ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# Переменные по умолчанию (если не заданы в .env)
GRAFANA_PORT ?= 3000
LOKI_PORT ?= 3100
PROMTAIL_PORT ?= 9080

# Пути к данным
LOKI_DATA_PATH ?= ./loki-data
GRAFANA_DATA_PATH ?= ./grafana-data
LOG_SOURCE_PATH ?= ./logs

.PHONY: help start stop restart logs status clean test-logs test-logs-stop test-logs-tail setup clean-install env-check

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
		if [ -f .env.example ]; then \
			cp .env.example .env; \
			echo "$(GREEN)Создан файл .env из .env.example$(NC)"; \
		else \
			echo "$(YELLOW)Файл .env.example не найден. Создайте .env вручную.$(NC)"; \
		fi; \
	else \
		echo "$(GREEN)Файл .env уже существует$(NC)"; \
	fi
	@echo "$(GREEN)Настройка завершена!$(NC)"
	@echo "$(YELLOW)Проверьте настройки: make env-check$(NC)"
	@echo "$(YELLOW)Затем запустите: make start$(NC)"

env-check: ## Показать текущие переменные окружения
	@echo "$(GREEN)Текущие переменные окружения:$(NC)"
	@echo "  $(YELLOW)GRAFANA_PORT:$(NC) $(GRAFANA_PORT)"
	@echo "  $(YELLOW)LOKI_PORT:$(NC) $(LOKI_PORT)"
	@echo "  $(YELLOW)PROMTAIL_PORT:$(NC) $(PROMTAIL_PORT)"
	@echo "  $(YELLOW)LOKI_DATA_PATH:$(NC) $(LOKI_DATA_PATH)"
	@echo "  $(YELLOW)GRAFANA_DATA_PATH:$(NC) $(GRAFANA_DATA_PATH)"
	@echo "  $(YELLOW)LOG_SOURCE_PATH:$(NC) $(LOG_SOURCE_PATH)"
	@echo ""
	@if [ -f .env ]; then \
		echo "$(GREEN)Файл .env найден$(NC)"; \
	else \
		echo "$(YELLOW)Файл .env не найден. Используются значения по умолчанию.$(NC)"; \
		echo "$(YELLOW)Запустите 'make setup' для создания .env$(NC)"; \
	fi

start: ## Запустить все сервисы
	@echo "$(GREEN)Запуск сервисов мониторинга...$(NC)"
	@mkdir -p $(LOKI_DATA_PATH) $(GRAFANA_DATA_PATH) $(LOG_SOURCE_PATH)
	@docker compose up -d
	@echo "$(GREEN)Сервисы запущены!$(NC)"
	@echo "$(YELLOW)Grafana доступна по адресу: http://localhost:$(GRAFANA_PORT)$(NC)"
	@echo "$(YELLOW)Логин: admin, Пароль: admin$(NC)"

stop: ## Остановить все сервисы
	@echo "$(GREEN)Остановка сервисов...$(NC)"
	@docker compose down
	@echo "$(GREEN)Сервисы остановлены$(NC)"

restart: ## Перезапустить все сервисы
	@echo "$(GREEN)Перезапуск сервисов...$(NC)"
	@docker compose restart
	@echo "$(GREEN)Сервисы перезапущены$(NC)"

logs: ## Показать логи всех сервисов
	@docker compose logs -f

logs-loki: ## Показать логи Loki
	@docker compose logs -f loki

logs-promtail: ## Показать логи Promtail
	@docker compose logs -f promtail

logs-grafana: ## Показать логи Grafana
	@docker compose logs -f grafana

status: ## Показать статус сервисов
	@echo "$(GREEN)Статус сервисов:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(GREEN)Проверка доступности:$(NC)"
	@printf "  Grafana ($(GRAFANA_PORT)): "; \
	curl -s http://localhost:$(GRAFANA_PORT)/api/health > /dev/null && echo "$(GREEN)✓ OK$(NC)" || echo "$(YELLOW)✗ Недоступна$(NC)"; \
	printf "  Loki ($(LOKI_PORT)):    "; \
	curl -s http://localhost:$(LOKI_PORT)/ready > /dev/null && echo "$(GREEN)✓ OK$(NC)" || echo "$(YELLOW)✗ Недоступен$(NC)"

test-logs: ## Создать тестовые логи (запускает демо приложение)
	@echo "$(GREEN)Запуск демо приложения для генерации логов...$(NC)"
	@mkdir -p $(LOG_SOURCE_PATH)
	@(cd go-demo && go run main.go) > $(LOG_SOURCE_PATH)/app.log 2>&1 &
	@sleep 2
	@echo "$(GREEN)Демо приложение запущено и пишет логи в $(LOG_SOURCE_PATH)/app.log$(NC)"
	@echo "$(YELLOW)Проверьте логи: make test-logs-tail$(NC)"
	@echo "$(YELLOW)Остановите: make test-logs-stop$(NC)"
	@echo "$(YELLOW)Логи появятся в Grafana через несколько секунд: http://localhost:$(GRAFANA_PORT)$(NC)"

test-logs-stop: ## Остановить демо приложение
	@echo "$(GREEN)Остановка демо приложения...$(NC)"
	@pkill -f 'go run main.go' 2>/dev/null || echo "$(YELLOW)Демо приложение не запущено$(NC)"
	@echo "$(GREEN)Демо приложение остановлено$(NC)"

test-logs-tail: ## Показать логи демо приложения
	@if [ -f $(LOG_SOURCE_PATH)/app.log ]; then \
		tail -f $(LOG_SOURCE_PATH)/app.log; \
	else \
		echo "$(YELLOW)Файл логов не найден. Запустите: make test-logs$(NC)"; \
	fi

clean: ## Очистить все данные (будет запрошено подтверждение)
	@echo "$(YELLOW)ВНИМАНИЕ: Это удалит все данные Loki и Grafana!$(NC)"
	@echo "$(YELLOW)Нажмите Ctrl+C для отмены, Enter для продолжения$(NC)"
	@read confirm
	@echo "$(GREEN)Остановка сервисов...$(NC)"
	@docker compose down
	@echo "$(GREEN)Удаление данных...$(NC)"
	@rm -rf $(LOKI_DATA_PATH)/* $(GRAFANA_DATA_PATH)/*
	@echo "$(GREEN)Данные удалены$(NC)"

update: ## Обновить Docker образы до последних версий
	@echo "$(GREEN)Обновление образов...$(NC)"
	@docker compose pull
	@echo "$(GREEN)Образы обновлены. Выполните 'make restart' для применения$(NC)"

backup: ## Создать резервную копию конфигурации и данных
	@echo "$(GREEN)Создание резервной копии...$(NC)"
	@mkdir -p backups
	@tar -czf backups/monitoring-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		config/ $(LOKI_DATA_PATH) $(GRAFANA_DATA_PATH) .env docker-compose.yml 2>/dev/null || true
	@echo "$(GREEN)Резервная копия создана в директории backups/$(NC)"

check: ## Проверить конфигурацию Docker Compose
	@echo "$(GREEN)Проверка конфигурации...$(NC)"
	@docker compose config

clean-install: ## Чистая установка (clean + start)
	@echo "$(GREEN)Выполняется чистая установка...$(NC)"
	@$(MAKE) clean
	@$(MAKE) start
