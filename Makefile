.PHONY: help start stop restart logs status clean test-logs setup

# Цвета для вывода
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Показать это сообщение помощи
	@echo "$(GREEN)Доступные команды:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Первоначальная настройка
	@echo "$(GREEN)Проверка конфигурации...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Создание .env файла...$(NC)"; \
		echo "GRAFANA_PORT=3000" > .env; \
		echo "LOKI_PORT=3100" >> .env; \
		echo "LOKI_DATA_PATH=/var/lib/docker/volumes/loki-data/_data" >> .env; \
		echo "GRAFANA_DATA_PATH=/var/lib/docker/volumes/grafana-data/_data" >> .env; \
		echo "LOG_SOURCE_PATH=./logs" >> .env; \
		echo "GRAFANA_ADMIN_USER=admin" >> .env; \
		echo "GRAFANA_ADMIN_PASSWORD=admin" >> .env; \
	fi
	@echo "$(GREEN)Настройка завершена!$(NC)"
	@echo "$(YELLOW)Теперь выполните: make start$(NC)"

start: ## Запустить все сервисы
	@echo "$(GREEN)Запуск сервисов мониторинга...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)Сервисы запущены!$(NC)"
	@GRAFANA_PORT=$$(grep GRAFANA_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3000"); \
	echo "$(YELLOW)Grafana доступна по адресу: http://localhost:$$GRAFANA_PORT$(NC)"; \
	echo "$(YELLOW)Логин: admin, Пароль: admin$(NC)"

stop: ## Остановить все сервисы
	@echo "$(GREEN)Остановка сервисов...$(NC)"
	@docker-compose down
	@echo "$(GREEN)Сервисы остановлены$(NC)"

restart: ## Перезапустить все сервисы
	@echo "$(GREEN)Перезапуск сервисов...$(NC)"
	@docker-compose restart
	@echo "$(GREEN)Сервисы перезапущены$(NC)"

logs: ## Показать логи всех сервисов
	@docker-compose logs -f

logs-loki: ## Показать логи Loki
	@docker-compose logs -f loki

logs-promtail: ## Показать логи Promtail
	@docker-compose logs -f promtail

logs-grafana: ## Показать логи Grafana
	@docker-compose logs -f grafana

status: ## Показать статус сервисов
	@echo "$(GREEN)Статус сервисов:$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(GREEN)Проверка доступности:$(NC)"
	@GRAFANA_PORT=$$(grep GRAFANA_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3000"); \
	LOKI_PORT=$$(grep LOKI_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3100"); \
	printf "  Grafana ($$GRAFANA_PORT): "; \
	curl -s http://localhost:$$GRAFANA_PORT/api/health > /dev/null && echo "$(GREEN)✓ OK$(NC)" || echo "$(YELLOW)✗ Недоступна$(NC)"; \
	printf "  Loki ($$LOKI_PORT):    "; \
	curl -s http://localhost:$$LOKI_PORT/ready > /dev/null && echo "$(GREEN)✓ OK$(NC)" || echo "$(YELLOW)✗ Недоступен$(NC)"

test-logs: ## Создать тестовые логи (запускает демо приложение)
	@echo "$(GREEN)Запуск демо приложения для генерации логов...$(NC)"
	@mkdir -p logs
	@cd go-demo && (go run main.go > ../logs/app.log 2>&1 &)
	@sleep 2
	@echo "$(GREEN)Демо приложение запущено и пишет логи в logs/app.log$(NC)"
	@echo "$(YELLOW)Проверьте логи: tail -f logs/app.log$(NC)"
	@echo "$(YELLOW)Остановите: pkill -f 'go run main.go'$(NC)"
	@GRAFANA_PORT=$$(grep GRAFANA_PORT .env 2>/dev/null | cut -d '=' -f2 || echo "3000"); \
	echo "$(YELLOW)Логи появятся в Grafana через несколько секунд: http://localhost:$$GRAFANA_PORT$(NC)"

clean: ## Очистить все данные (будет запрошено подтверждение)
	@echo "$(YELLOW)ВНИМАНИЕ: Это удалит все данные Loki и Grafana!$(NC)"
	@echo "$(YELLOW)Нажмите Ctrl+C для отмены, Enter для продолжения$(NC)"
	@read confirm
	@echo "$(GREEN)Остановка сервисов...$(NC)"
	@docker-compose down
	@echo "$(GREEN)Удаление данных...$(NC)"
	@rm -rf data/loki/* data/grafana/*
	@echo "$(GREEN)Данные удалены$(NC)"

update: ## Обновить Docker образы до последних версий
	@echo "$(GREEN)Обновление образов...$(NC)"
	@docker-compose pull
	@echo "$(GREEN)Образы обновлены. Выполните 'make restart' для применения$(NC)"

backup: ## Создать резервную копию конфигурации и данных
	@echo "$(GREEN)Создание резервной копии...$(NC)"
	@mkdir -p backups
	@tar -czf backups/monitoring-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		config/ data/ .env docker-compose.yml 2>/dev/null || true
	@echo "$(GREEN)Резервная копия создана в директории backups/$(NC)"

check: ## Проверить конфигурацию Docker Compose
	@echo "$(GREEN)Проверка конфигурации...$(NC)"
	@docker-compose config
