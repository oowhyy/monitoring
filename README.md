# 📊 Система мониторинга логов (Promtail + Loki + Grafana)

Полноценная система для сбора, хранения и визуализации логов с использованием современного стека инструментов от Grafana Labs.

> **🚀 Быстрый старт:** `make setup && make start && make test-logs` → http://localhost:3000  
> **📖 Новичок?** Начните с [FIRST_RUN.md](FIRST_RUN.md) | **⚡ Опытный?** Смотрите [QUICKSTART.md](QUICKSTART.md)  
> **🗺️ Навигация:** [INDEX.md](INDEX.md) содержит полный индекс документации

## 📋 Содержание

- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Установка с нуля](#установка-с-нуля)
- [Конфигурация](#конфигурация)
- [Использование Grafana](#использование-grafana)
- [Интеграция с приложением](#интеграция-с-приложением)
- [Документация](#документация)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## 🏗 Архитектура

Система состоит из трех компонентов:

```
┌─────────────────┐         ┌──────────────┐         ┌──────────────┐
│   Приложение    │────────▶│   Promtail   │────────▶│     Loki     │
│  (Go + Zap)     │  логи   │   (агент)    │  логи   │ (хранилище)  │
└─────────────────┘         └──────────────┘         └──────────────┘
                                                             │
                                                             │ запросы
                                                             ▼
                                                      ┌──────────────┐
                                                      │   Grafana    │
                                                      │(визуализация)│
                                                      └──────────────┘
```

### Компоненты

- **Promtail** - агент для сбора логов из файлов
  - Читает лог-файлы в реальном времени
  - Парсит JSON формат (zap logger)
  - Добавляет метки и метаданные
  - Отправляет в Loki

- **Loki** - система хранения и индексации логов
  - Эффективное хранение временных рядов логов
  - Индексация по меткам (labels)
  - Быстрый поиск по LogQL запросам
  - Поддержка retention policies

- **Grafana** - платформа для визуализации
  - Красивые дашборды
  - Мощные инструменты поиска и фильтрации
  - Алерты и уведомления
  - Экспорт и шаринг

---

## 🚀 Быстрый старт

### Предварительные требования

- Docker и Docker Compose установлены
- Минимум 2GB свободной RAM
- Порты 3000 и 3100 свободны

### Запуск за 3 шага

```bash
# 1. Клонировать или перейти в директорию проекта
cd /path/to/monitoring

# 2. Запустить систему (директории создадутся автоматически)
docker-compose up -d
```

### Проверка работы

1. Откройте Grafana: http://localhost:3000
2. Войдите (admin/admin)
3. Перейдите в Dashboards → Go Application Logs
4. Добавьте тестовые логи:

```bash
# Создайте тестовый лог-файл
echo '{"level":"info","ts":"2024-01-01T12:00:00.000Z","logger":"test","msg":"Test message"}' > logs/app.log
```

Через несколько секунд лог появится в Grafana! 🎉

---

## 🔧 Установка с нуля

### Шаг 1: Установка Docker

<details>
<summary><b>MacOS</b></summary>

```bash
# Установка через Homebrew
brew install --cask docker

# Или скачайте Docker Desktop с официального сайта
# https://www.docker.com/products/docker-desktop/
```

После установки запустите Docker Desktop из Applications.
</details>

<details>
<summary><b>Ubuntu/Debian</b></summary>

```bash
# Обновление пакетов
sudo apt-get update

# Установка зависимостей
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавление Docker GPG ключа
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавление репозитория
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавление пользователя в группу docker (чтобы не использовать sudo)
sudo usermod -aG docker $USER
newgrp docker
```
</details>

<details>
<summary><b>Windows</b></summary>

1. Скачайте Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Запустите установщик
3. Следуйте инструкциям установщика
4. Перезагрузите компьютер
5. Запустите Docker Desktop

**Примечание:** Требуется WSL2 для работы Docker на Windows.
</details>

### Шаг 2: Проверка установки Docker

```bash
# Проверка версии Docker
docker --version
# Ожидаемый результат: Docker version 24.0.0+

# Проверка Docker Compose
docker-compose --version
# Ожидаемый результат: Docker Compose version v2.20.0+

# Тестовый запуск
docker run hello-world
```

### Шаг 3: Подготовка проекта

```bash
# Создайте директорию для проекта (если еще не создана)
mkdir -p ~/monitoring
cd ~/monitoring

# Скопируйте все файлы проекта в эту директорию
# Структура должна быть следующей:
# monitoring/
# ├── docker-compose.yml
# ├── .env.example
# ├── .gitignore
# ├── README.md
# └── config/
#     ├── loki-config.yml
#     ├── promtail-config.yml
#     └── grafana/
#         └── provisioning/
#             ├── datasources/
#             │   └── loki.yml
#             └── dashboards/
#                 ├── dashboard.yml
#                 └── definitions/
#                     └── go-application-logs.json
```

### Шаг 4: Создание необходимых директорий

```bash
# Создание директории для логов приложения (опционально)
mkdir -p logs
```

**Примечание:** Docker автоматически создаст volumes для Loki и Grafana при первом запуске.

### Шаг 5: Конфигурация переменных окружения

```bash
# Скопируйте .env.example в .env
cp .env.example .env

# Отредактируйте .env файл под свои нужды
nano .env
# или
vim .env
```

### Шаг 6: Запуск системы

```bash
# Запуск в фоновом режиме
docker-compose up -d

# Проверка статуса контейнеров
docker-compose ps

# Просмотр логов (опционально)
docker-compose logs -f
```

### Шаг 7: Первый вход в Grafana

1. Откройте браузер и перейдите на http://localhost:3000
2. Введите логин: `admin`
3. Введите пароль: `admin`
4. Grafana попросит сменить пароль (можно пропустить)

---

## ⚙️ Конфигурация

### Переменные окружения (.env)

Создайте файл `.env` в корне проекта:

```bash
# Порты сервисов
GRAFANA_PORT=3000          # Порт для веб-интерфейса Grafana
LOKI_PORT=3100             # Порт API Loki

# Пути к данным на хосте
LOKI_DATA_PATH=/var/lib/docker/volumes/loki-data/_data     # Хранилище данных Loki
GRAFANA_DATA_PATH=/var/lib/docker/volumes/grafana-data/_data  # Хранилище данных Grafana

# Путь к логам приложения (ВАЖНО!)
LOG_SOURCE_PATH=./logs              # Директория с лог-файлами

# Учетные данные Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin        # Измените в продакшене!
```

### Настройка путей к логам

#### Вариант 1: Локальная директория

```bash
# В .env файле
LOG_SOURCE_PATH=./logs
```

```bash
# Создание директории
mkdir -p logs

# Ваше приложение должно писать логи в эту директорию
```

#### Вариант 2: Абсолютный путь

```bash
# В .env файле
LOG_SOURCE_PATH=/var/log/myapp
```

```bash
# Убедитесь, что директория существует
mkdir -p /var/log/myapp
chmod 755 /var/log/myapp
```

#### Вариант 3: Несколько источников логов

Отредактируйте `docker-compose.yml`:

```yaml
  promtail:
    volumes:
      - ./config/promtail-config.yml:/etc/promtail/config.yml
      - ${LOG_SOURCE_PATH:-./logs}:/var/log/app:ro
      - /var/log/nginx:/var/log/nginx:ro           # Nginx логи
      - /var/log/myapp:/var/log/myapp:ro           # Другое приложение
```

И обновите `config/promtail-config.yml`, добавив новые job'ы.

### Настройка портов

Если порты 3000 или 3100 заняты:

```bash
# В .env файле измените порты
GRAFANA_PORT=3001
LOKI_PORT=3101
```

После изменения перезапустите:

```bash
docker-compose down
docker-compose up -d
```

### Настройка retention (хранение логов)

По умолчанию логи хранятся 30 дней. Для изменения отредактируйте `config/loki-config.yml`:

```yaml
# Хранить логи 7 дней
chunk_store_config:
  max_look_back_period: 168h  # 7 дней

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h  # 7 дней
```

---

## 📊 Использование Grafana

### Интерфейс Grafana

После входа в Grafana вы увидите главную страницу с несколькими разделами:

#### 1. Главное меню (слева)

- **Home** - главная страница
- **Dashboards** - список всех дашбордов
- **Explore** - интерактивное исследование логов
- **Alerting** - настройка алертов
- **Configuration** - настройки Grafana

### Работа с готовым дашбордом

Перейдите: **Dashboards → Logs → Go Application Logs**

Дашборд содержит:

#### 1. График логов по уровням (Log Levels Over Time)
- Визуализация количества логов каждого уровня во времени
- Цветовая кодировка: Error (красный), Warn (оранжевый), Info (синий), Debug (зеленый)

#### 2. Статистические панели
- **Ошибки за последние 5 минут** - красная панель с количеством ошибок
- **Предупреждения за последние 5 минут** - желтая панель
- **Info логи за последние 5 минут** - синяя панель
- **Всего логов за последние 5 минут** - общее количество

#### 3. Логи приложения (Application Logs)
- Поток всех логов в реальном времени
- Фильтрация по уровням
- Раскрытие детальной информации по клику

#### 4. Только ошибки (Errors Only)
- Отдельная панель только с логами уровня ERROR
- Удобно для мониторинга проблем

### Фильтры и переменные

В верхней части дашборда есть dropdown'ы:

- **Job** - выбор источника логов (по умолчанию go-application)
- **Log Level** - фильтр по уровням логов (All, error, warn, info, debug)

### Временной диапазон

В правом верхнем углу:
- **Last 1 hour** - по умолчанию показывает логи за последний час
- Можно выбрать другой диапазон: 5m, 15m, 1h, 6h, 24h, 7d, 30d
- Или указать custom диапазон

### Автообновление

Рядом с временным диапазоном:
- Кнопка **🔄** - обновить вручную
- Dropdown для автообновления: Off, 5s, 10s, 30s, 1m, 5m

### Explore - интерактивное исследование

Для более гибкого поиска используйте **Explore**:

1. Перейдите в **Explore** из главного меню
2. Выберите datasource: **Loki**
3. Используйте LogQL запросы

#### Примеры LogQL запросов:

```logql
# Все логи приложения
{job="go-application"}

# Только ошибки
{job="go-application", level="error"}

# Поиск по тексту
{job="go-application"} |= "database connection"

# Поиск с регулярным выражением
{job="go-application"} |~ "error|exception"

# Исключение определенных логов
{job="go-application"} != "health check"

# Парсинг JSON и фильтрация
{job="go-application"} | json | user_id="12345"

# Подсчет логов за интервал
sum(count_over_time({job="go-application"}[5m]))

# Топ ошибок
topk(10, sum by (error) (count_over_time({job="go-application", level="error"}[1h])))
```

### Создание своего дашборда

1. **Dashboard** → **New Dashboard** → **Add visualization**
2. Выберите datasource: **Loki**
3. Напишите LogQL запрос
4. Выберите тип визуализации:
   - **Logs** - поток логов
   - **Time series** - график
   - **Stat** - числовое значение
   - **Table** - таблица
5. Настройте панель (заголовок, цвета, пороги)
6. **Save dashboard**

### Экспорт дашборда

1. Откройте дашборд
2. Нажмите на ⚙️ (Settings) в правом верхнем углу
3. **JSON Model** → скопируйте JSON
4. Сохраните в файл для переиспользования

---

## 🔌 Интеграция с приложением

### Go приложение с Zap logger

#### Установка Zap

```bash
go get -u go.uber.org/zap
```

#### Пример конфигурации (пишет в stdout)

```go
package main

import (
    "os"
    "go.uber.org/zap"
    "go.uber.org/zap/zapcore"
)

func initLogger() *zap.Logger {
    // Конфигурация encoder для JSON формата
    encoderConfig := zapcore.EncoderConfig{
        TimeKey:        "ts",
        LevelKey:       "level",
        NameKey:        "logger",
        CallerKey:      "caller",
        FunctionKey:    zapcore.OmitKey,
        MessageKey:     "msg",
        StacktraceKey:  "stacktrace",
        LineEnding:     zapcore.DefaultLineEnding,
        EncodeLevel:    zapcore.LowercaseLevelEncoder,
        EncodeTime:     zapcore.RFC3339NanoTimeEncoder,
        EncodeDuration: zapcore.SecondsDurationEncoder,
        EncodeCaller:   zapcore.ShortCallerEncoder,
    }

    // Core с JSON encoder, пишет в stdout
    core := zapcore.NewCore(
        zapcore.NewJSONEncoder(encoderConfig),
        zapcore.AddSync(os.Stdout),
        zap.InfoLevel,
    )

    // Создание logger
    logger := zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))
    
    return logger
}

func main() {
    logger := initLogger()
    defer logger.Sync()

    // Примеры использования
    logger.Info("Application started",
        zap.String("version", "1.0.0"),
        zap.Int("port", 8080),
    )

    logger.Warn("Configuration value is missing",
        zap.String("key", "database.host"),
    )

    logger.Error("Failed to connect to database",
        zap.String("host", "localhost"),
        zap.Int("port", 5432),
        zap.Error(fmt.Errorf("connection refused")),
    )

    // Структурированные логи с дополнительными полями
    logger.Info("User action",
        zap.String("user_id", "12345"),
        zap.String("action", "login"),
        zap.String("ip", "192.168.1.1"),
    )
}
```

#### Запуск с сохранением логов

```bash
# Соберите приложение
go build -o myapp

# Запустите с перенаправлением в файл
./myapp > logs/app.log 2>&1 &

# Или используйте systemd/supervisor для управления процессом
```

#### Ротация логов

Используйте системные инструменты для ротации:

**Linux (logrotate):**

Создайте `/etc/logrotate.d/myapp`:
```
/path/to/monitoring/logs/app.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

**Или используйте утилиту rotatelogs:**
```bash
./myapp | rotatelogs logs/app.log.%Y-%m-%d 86400 &
```

**Или Unix pipe с tee:**
```bash
# Пишет в файл и в stdout одновременно
./myapp | tee -a logs/app.log
```

### Проверка интеграции

```bash
# Запустите ваше Go приложение с перенаправлением
cd go-demo
go run main.go > ../logs/app.log 2>&1 &

# Проверьте, что логи пишутся
tail -f ../logs/app.log

# Через несколько секунд логи должны появиться в Grafana
```

### Универсальный подход

Любая программа, которая пишет JSON в stdout, работает так же:

```bash
# Python
python3 myapp.py > logs/app.log 2>&1 &

# Node.js
node myapp.js > logs/app.log 2>&1 &

# Rust
./myapp > logs/app.log 2>&1 &

# Docker контейнер
docker logs -f my-container > logs/app.log 2>&1 &
```

---

## 📚 Документация

### Официальная документация компонентов

#### Loki
- **Главная документация**: https://grafana.com/docs/loki/latest/
- **Конфигурация**: https://grafana.com/docs/loki/latest/configuration/
- **LogQL (язык запросов)**: https://grafana.com/docs/loki/latest/logql/
- **Best Practices**: https://grafana.com/docs/loki/latest/best-practices/

#### Promtail
- **Главная документация**: https://grafana.com/docs/loki/latest/clients/promtail/
- **Конфигурация**: https://grafana.com/docs/loki/latest/clients/promtail/configuration/
- **Pipeline stages**: https://grafana.com/docs/loki/latest/clients/promtail/stages/
- **Scraping**: https://grafana.com/docs/loki/latest/clients/promtail/scraping/

#### Grafana
- **Главная документация**: https://grafana.com/docs/grafana/latest/
- **Getting Started**: https://grafana.com/docs/grafana/latest/getting-started/
- **Provisioning**: https://grafana.com/docs/grafana/latest/administration/provisioning/
- **Loki datasource**: https://grafana.com/docs/grafana/latest/datasources/loki/

### Создание дашбордов

- **Dashboard Guide**: https://grafana.com/docs/grafana/latest/dashboards/
- **Panel types**: https://grafana.com/docs/grafana/latest/panels-visualizations/
- **Variables**: https://grafana.com/docs/grafana/latest/dashboards/variables/
- **Transformations**: https://grafana.com/docs/grafana/latest/panels-visualizations/query-transform-data/transform-data/
- **Alerting**: https://grafana.com/docs/grafana/latest/alerting/

### Дополнительные ресурсы

- **Grafana Community**: https://community.grafana.com/
- **Grafana Labs GitHub**: https://github.com/grafana
- **Dashboard библиотека**: https://grafana.com/grafana/dashboards/
- **Tutorials**: https://grafana.com/tutorials/

---

## 🔧 Troubleshooting

### Проблема: Контейнеры не запускаются

**Симптомы:**
```bash
docker-compose ps
# Показывает Exit (1) или контейнеры постоянно перезапускаются
```

**Решение:**

1. Проверьте логи:
```bash
docker-compose logs loki
docker-compose logs promtail
docker-compose logs grafana
```

2. Проверьте права доступа к директориям:
```bash
# Если используете кастомные пути (не Docker volumes)
# Linux/MacOS
sudo chmod -R 755 logs

# Для Docker volumes права устанавливаются автоматически
```

3. Убедитесь, что порты свободны:
```bash
# MacOS/Linux
lsof -i :3000
lsof -i :3100

# Если порты заняты, измените их в .env файле
```

---

### Проблема: Grafana не показывает логи

**Симптомы:**
- Дашборд пустой
- "No data" в панелях

**Решение:**

1. Проверьте datasource:
```
Grafana → Configuration → Data Sources → Loki
Нажмите "Test" → должно быть "Data source is working"
```

2. Проверьте, что Promtail отправляет данные в Loki:
```bash
# Проверка API Loki
curl http://localhost:3100/ready
# Должно вернуть "ready"

# Проверка меток (labels)
curl http://localhost:3100/loki/api/v1/labels
# Должен вернуть JSON с метками, например: {"values":["job","level"]}
```

3. Проверьте лог-файлы:
```bash
# Убедитесь, что файлы логов существуют
ls -la logs/

# Проверьте содержимое
cat logs/app.log
```

4. Проверьте формат логов:
```bash
# Логи должны быть в JSON формате
# Правильно:
{"level":"info","ts":"2024-01-01T12:00:00Z","msg":"Test"}

# Неправильно:
2024-01-01 12:00:00 INFO Test
```

5. Проверьте путь в Promtail:
```bash
# Проверьте, что путь в docker-compose.yml совпадает с реальным
docker-compose exec promtail ls -la /var/log/app/
```

---

### Проблема: Promtail не читает логи

**Симптомы:**
- Лог-файлы существуют, но не появляются в Grafana
- В логах Promtail нет ошибок

**Решение:**

1. Проверьте конфигурацию Promtail:
```bash
docker-compose exec promtail cat /etc/promtail/config.yml
```

2. Проверьте путь к логам:
```yaml
# В promtail-config.yml должен быть правильный __path__
__path__: /var/log/app/*.log  # Соответствует volume в docker-compose
```

3. Проверьте права доступа:
```bash
# Promtail должен иметь доступ на чтение
chmod 644 logs/*.log
```

4. Проверьте, что логи не старые:
```bash
# Loki по умолчанию отклоняет логи старше 7 дней
# Создайте свежий лог-файл для теста
echo '{"level":"info","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","msg":"Test"}' > logs/test.log
```

5. Перезапустите Promtail:
```bash
docker-compose restart promtail
```

---

### Проблема: "Permission denied" при записи логов

**Симптомы:**
```bash
open logs/app.log: permission denied
```

**Решение:**

```bash
# Создайте директорию с правильными правами
mkdir -p logs
chmod 755 logs

# Проверьте владельца
ls -la logs/

# Убедитесь, что пользователь может писать
touch logs/test.log && rm logs/test.log
```

---

### Проблема: Grafana не сохраняет дашборды

**Симптомы:**
- Изменения в дашборде не сохраняются после перезапуска
- При перезапуске дашборд возвращается к исходному состоянию

**Причина:**
Дашборд загружается из provisioning (Infrastructure as Code).

**Решение:**

1. Если вы хотите редактировать через UI:
   - Сделайте копию дашборда (Save As)
   - Новый дашборд будет сохранен в БД Grafana

2. Если вы хотите изменить provisioned дашборд:
   - Отредактируйте файл `config/grafana/provisioning/dashboards/definitions/go-application-logs.json`
   - Перезапустите Grafana: `docker-compose restart grafana`

---

### Проблема: Высокое использование диска

**Симптомы:**
```bash
df -h
# Показывает, что диск заполнен
```

**Решение:**

1. Проверьте размер данных Loki:
```bash
du -sh data/loki
```

2. Настройте retention (см. раздел Конфигурация):
```yaml
# В loki-config.yml уменьшите retention
retention_period: 168h  # 7 дней вместо 30
```

3. Очистите старые данные вручную:
```bash
# ВНИМАНИЕ: Удалит все данные Loki!
docker-compose down
rm -rf data/loki/*
docker-compose up -d
```

4. Настройте ротацию логов в приложении (см. раздел Интеграция).

---

### Проблема: Медленные запросы в Grafana

**Симптомы:**
- Дашборды долго загружаются
- Таймауты при больших временных диапазонах

**Решение:**

1. Уменьшите временной диапазон:
   - Вместо "Last 7 days" используйте "Last 6 hours"

2. Используйте более специфичные фильтры:
```logql
# Плохо (сканирует все логи)
{job="go-application"}

# Хорошо (использует индекс)
{job="go-application", level="error"}
```

3. Используйте агрегацию:
```logql
# Вместо всех логов
sum(count_over_time({job="go-application"}[5m]))
```

4. Настройте кэширование в loki-config.yml (уже включено по умолчанию).

---

### Проблема: Docker контейнер Grafana падает на MacOS

**Симптомы:**
```
grafana exited with code 1
```

**Решение:**

```bash
# При использовании Docker volumes проблема решается автоматически
# Если используете кастомный путь, проверьте права:
ls -la $GRAFANA_DATA_PATH

# Перезапуск
docker-compose up -d grafana
```

---

### Проблема: LogQL запрос возвращает ошибку

**Примеры ошибок и решения:**

1. **"parse error: syntax error"**
```logql
# Неправильно
{job=go-application}

# Правильно
{job="go-application"}
```

2. **"too many outstanding requests"**
- Система перегружена запросами
- Уменьшите временной диапазон
- Добавьте больше ресурсов (RAM) контейнеру Loki

3. **"maximum of series reached"**
```yaml
# В loki-config.yml увеличьте лимит
limits_config:
  max_query_series: 5000  # Было 1000
```

---

## ❓ FAQ

### Можно ли использовать в продакшене?

Да, но с доработками:
- Настройте authentication и authorization в Grafana
- Используйте внешнюю БД для Grafana (PostgreSQL)
- Настройте TLS/HTTPS
- Используйте секреты вместо .env файла
- Настройте backup для данных
- Рассмотрите кластерную настройку Loki для high availability

### Как добавить алерты?

1. В Grafana перейдите в **Alerting → Alert rules**
2. **New alert rule**
3. Напишите LogQL запрос для условия алерта:
```logql
sum(count_over_time({job="go-application", level="error"}[5m])) > 10
```
4. Настройте канал уведомлений (email, Slack, PagerDuty и т.д.)

### Как экспортировать логи?

```bash
# Через API Loki
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="go-application"}' \
  --data-urlencode 'start=1609459200000000000' \
  --data-urlencode 'end=1609545600000000000' \
  | jq > logs_export.json
```

### Можно ли использовать с другими языками программирования?

Да! Главное - чтобы логи были в JSON формате. Примеры:

**Python (structlog)**
```python
import structlog
logger = structlog.get_logger()
logger.info("test", user_id=123)
```

**Node.js (winston)**
```javascript
const winston = require('winston');
const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [new winston.transports.File({ filename: 'app.log' })]
});
```

**Java (logback with JSON encoder)**
```xml
<encoder class="net.logstash.logback.encoder.LogstashEncoder"/>
```

### Как мониторить несколько приложений?

Добавьте разные job'ы в `promtail-config.yml`:

```yaml
scrape_configs:
  - job_name: app1
    static_configs:
      - targets: [localhost]
        labels:
          job: app1
          __path__: /var/log/app1/*.log

  - job_name: app2
    static_configs:
      - targets: [localhost]
        labels:
          job: app2
          __path__: /var/log/app2/*.log
```

И добавьте volumes в `docker-compose.yml`:

```yaml
promtail:
  volumes:
    - ./logs/app1:/var/log/app1:ro
    - ./logs/app2:/var/log/app2:ro
```

### Как обновить систему?

```bash
# Остановка контейнеров
docker-compose down

# Обновление образов
docker-compose pull

# Запуск с новыми версиями
docker-compose up -d

# Проверка версий
docker-compose exec loki loki --version
docker-compose exec grafana grafana-cli --version
```

### Сколько места на диске нужно?

Зависит от объема логов:
- **Небольшое приложение** (100 логов/сек): ~1-5 GB/день
- **Среднее приложение** (1000 логов/сек): ~10-50 GB/день
- **Большое приложение** (10000 логов/сек): ~100-500 GB/день

Используйте retention policy для ограничения хранения.

---

## 📞 Поддержка

Если вы столкнулись с проблемой, которая не описана в этом документе:

1. Проверьте логи всех контейнеров:
```bash
docker-compose logs
```

2. Проверьте официальную документацию (ссылки выше)

3. Поищите решение в сообществе:
   - https://community.grafana.com/
   - https://stackoverflow.com/questions/tagged/grafana-loki

4. Откройте issue на GitHub проекта

---

## 📝 Лицензия

Этот проект использует открытое ПО:
- Grafana - AGPLv3
- Loki - AGPLv3
- Promtail - Apache 2.0

---

## 🎉 Готово!

Теперь у вас есть полностью настроенная система мониторинга логов. Удачного мониторинга! 🚀

