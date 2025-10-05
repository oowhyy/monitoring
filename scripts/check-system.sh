#!/bin/bash

# Скрипт для проверки работоспособности системы мониторинга

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Проверка системы мониторинга логов             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверка Docker
echo -e "${YELLOW}[1/7] Проверка Docker...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "  ${GREEN}✓${NC} Docker установлен: $DOCKER_VERSION"
else
    echo -e "  ${RED}✗${NC} Docker не установлен!"
    exit 1
fi

# Проверка Docker Compose
echo -e "${YELLOW}[2/7] Проверка Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "  ${GREEN}✓${NC} Docker Compose установлен: $COMPOSE_VERSION"
else
    echo -e "  ${RED}✗${NC} Docker Compose не установлен!"
    exit 1
fi

# Проверка портов
echo -e "${YELLOW}[3/7] Проверка доступности портов...${NC}"

# Читаем порты из .env
GRAFANA_PORT=$(grep GRAFANA_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3000")
LOKI_PORT=$(grep LOKI_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3100")

check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "  ${GREEN}✓${NC} Порт $port ($name) используется"
    else
        echo -e "  ${YELLOW}○${NC} Порт $port ($name) свободен"
    fi
}

check_port $GRAFANA_PORT "Grafana"
check_port $LOKI_PORT "Loki"

# Проверка контейнеров
echo -e "${YELLOW}[4/7] Проверка контейнеров...${NC}"
if [ -f "docker-compose.yml" ]; then
    RUNNING_CONTAINERS=$(docker-compose ps -q 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Запущено контейнеров: $RUNNING_CONTAINERS"
        docker-compose ps
    else
        echo -e "  ${YELLOW}○${NC} Контейнеры не запущены"
    fi
else
    echo -e "  ${RED}✗${NC} Файл docker-compose.yml не найден!"
    exit 1
fi

# Проверка доступности сервисов
echo -e "${YELLOW}[5/7] Проверка доступности сервисов...${NC}"

# Grafana
if curl -s http://localhost:$GRAFANA_PORT/api/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Grafana доступна (http://localhost:$GRAFANA_PORT)"
else
    echo -e "  ${RED}✗${NC} Grafana недоступна"
fi

# Loki
if curl -s http://localhost:$LOKI_PORT/ready > /dev/null 2>&1; then
    LOKI_STATUS=$(curl -s http://localhost:$LOKI_PORT/ready)
    echo -e "  ${GREEN}✓${NC} Loki доступен (http://localhost:$LOKI_PORT) - Status: $LOKI_STATUS"
else
    echo -e "  ${RED}✗${NC} Loki недоступен"
fi

# Проверка конфигурационных файлов
echo -e "${YELLOW}[6/7] Проверка конфигурации...${NC}"
check_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file не найден!"
    fi
}

check_file "config/loki.yml"
check_file "config/promtail.yml"
check_file "config/grafana/provisioning/datasources/loki-source.yml"
check_file "config/grafana/provisioning/dashboards/dashboard.yml"

# Проверка директорий для данных
echo -e "${YELLOW}[7/7] Проверка директорий...${NC}"
check_dir() {
    local dir=$1
    if [ -d "$dir" ]; then
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}✓${NC} $dir (размер: $SIZE)"
    else
        echo -e "  ${YELLOW}○${NC} $dir не создана"
    fi
}

check_dir "data/loki"
check_dir "data/grafana"
check_dir "logs"

# Проверка логов
echo ""
echo -e "${YELLOW}Проверка наличия лог-файлов...${NC}"
if [ -d "logs" ] && [ "$(ls -A logs 2>/dev/null)" ]; then
    LOG_COUNT=$(find logs -name "*.log" | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} Найдено лог-файлов: $LOG_COUNT"
    ls -lh logs/*.log 2>/dev/null | head -5
else
    echo -e "  ${YELLOW}○${NC} Лог-файлы не найдены"
    echo -e "  ${YELLOW}Совет:${NC} Создайте тестовые логи: ${BLUE}make test-logs${NC}"
fi

# Проверка меток в Loki
echo ""
echo -e "${YELLOW}Проверка данных в Loki...${NC}"
if curl -s http://localhost:$LOKI_PORT/loki/api/v1/labels > /dev/null 2>&1; then
    LABELS=$(curl -s http://localhost:$LOKI_PORT/loki/api/v1/labels | jq -r '.data[]' 2>/dev/null | tr '\n' ', ')
    if [ -n "$LABELS" ]; then
        echo -e "  ${GREEN}✓${NC} Доступные метки в Loki: $LABELS"
    else
        echo -e "  ${YELLOW}○${NC} В Loki пока нет данных"
    fi
else
    echo -e "  ${RED}✗${NC} Не удается получить метки из Loki"
fi

# Итоговый статус
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   ИТОГОВЫЙ СТАТУС                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"

if curl -s http://localhost:$GRAFANA_PORT/api/health > /dev/null 2>&1 && \
   curl -s http://localhost:$LOKI_PORT/ready > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Система работает нормально!${NC}"
    echo ""
    echo -e "Доступ к интерфейсам:"
    echo -e "  • Grafana: ${BLUE}http://localhost:$GRAFANA_PORT${NC} (admin/admin)"
    echo -e "  • Loki API: ${BLUE}http://localhost:$LOKI_PORT${NC}"
    echo ""
    echo -e "Следующие шаги:"
    echo -e "  1. Откройте Grafana и перейдите в дашборд"
    echo -e "  2. Настройте ваше приложение для записи логов"
    echo -e "  3. Или создайте тестовые логи: ${YELLOW}make test-logs${NC}"
else
    echo -e "${YELLOW}⚠ Система запущена не полностью${NC}"
    echo ""
    echo -e "Попробуйте:"
    echo -e "  • ${YELLOW}docker-compose up -d${NC} - для запуска"
    echo -e "  • ${YELLOW}docker-compose logs${NC} - для проверки логов"
    echo -e "  • ${YELLOW}make status${NC} - для проверки статуса"
fi

echo ""
