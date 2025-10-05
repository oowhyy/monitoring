# Go Demo приложение с Zap логированием

Демонстрационное Go приложение, которое показывает правильную настройку Zap logger для интеграции с системой мониторинга (Promtail + Loki + Grafana).

## Особенности

- ✅ JSON формат логов (совместим с Promtail)
- ✅ Правильные названия полей (`ts`, `level`, `msg`, `logger`, `caller`)
- ✅ RFC3339Nano timestamp формат
- ✅ Запись логов в stdout (стандартный подход)
- ✅ Структурированное логирование с контекстными полями
- ✅ Универсальный подход - работает с любой программой

## Запуск

### Просто запуск (вывод в консоль)

```bash
cd go-demo
go run main.go
```

### Запуск с сохранением логов (для Promtail)

```bash
# Создайте директорию для логов (если еще не создана)
mkdir -p ../logs

# Запустите с перенаправлением в файл
cd go-demo
go run main.go > ../logs/app.log 2>&1

# Или в фоновом режиме
go run main.go > ../logs/app.log 2>&1 &
```

### Билд и запуск исполняемого файла

```bash
# Собрать исполняемый файл
cd go-demo
go build -o app

# Запустить с перенаправлением
./app > ../logs/app.log 2>&1 &
```

## Формат логов

Приложение генерирует логи в JSON формате, полностью совместимом с Promtail:

```json
{
  "level": "info",
  "ts": "2024-01-01T12:00:00.123456789Z",
  "logger": "app",
  "caller": "main.go:123",
  "msg": "Request processing completed",
  "service": "user-service",
  "request_id": "req456",
  "user_id": "user123",
  "total_duration": 0.1
}
```

## Куда пишутся логи

Приложение пишет логи в **stdout** (стандартный вывод). Это универсальный подход Unix-way.

Вы перенаправляете вывод куда хотите:
```bash
# В файл для Promtail
./app > ../logs/app.log

# В файл с ротацией (используя logrotate или аналоги)
./app | tee -a ../logs/app.log

# В несколько мест одновременно
./app | tee ../logs/app.log ../logs/backup.log
```

Структура проекта:
```
monitoring/
  ├── go-demo/
  │   ├── main.go
  │   └── app          ← Исполняемый файл
  └── logs/
      └── app.log      ← Вы перенаправляете сюда
```

## Примеры использования

### Базовое логирование

```go
logger.Info("Simple message",
    zap.String("key", "value"),
    zap.Int("count", 42),
)
```

### Логирование с ошибкой

```go
if err != nil {
    logger.Error("Operation failed",
        zap.Error(err),
        zap.String("operation", "database_query"),
    )
}
```

### Создание логгера с контекстом

```go
// Создаем логгер с постоянными полями
contextLogger := logger.With(
    zap.String("service", "user-service"),
    zap.String("request_id", requestID),
)

// Все логи от этого logger'а будут содержать эти поля
contextLogger.Info("Processing request")
contextLogger.Info("Request completed")
```

### Структурированные данные

```go
logger.Info("User created",
    zap.String("user_id", "123"),
    zap.String("email", "user@example.com"),
    zap.Bool("active", true),
    zap.Strings("roles", []string{"admin", "user"}),
)
```

## Интеграция с системой мониторинга

1. Запустите систему мониторинга:
```bash
cd /path/to/monitoring
docker-compose up -d
```

2. Запустите Go приложение с перенаправлением в файл:
```bash
cd go-demo
go run main.go > ../logs/app.log 2>&1 &
```

3. Откройте Grafana: http://localhost:3000 (admin/admin)

4. Перейдите в дашборд: **Dashboards → Logs → Go Application Logs**

5. Через несколько секунд увидите логи в реальном времени!

## Универсальность подхода

Этот же подход работает с **ЛЮБОЙ** программой, которая пишет JSON логи в stdout:

```bash
# Ваша программа на любом языке
./my-python-app > ../logs/app.log 2>&1 &
./my-node-app > ../logs/app.log 2>&1 &
./my-rust-app > ../logs/app.log 2>&1 &

# Docker контейнер
docker logs -f my-container > ../logs/app.log 2>&1 &

# Kubernetes pod
kubectl logs -f my-pod > ../logs/app.log 2>&1 &
```

Promtail следит за файлами в `logs/` директории и отправляет всё в Loki!

## Устранение проблем

### Логи не появляются в Grafana

1. Проверьте, что файл логов создается:
```bash
ls -la ../logs/
cat ../logs/app.log
```

2. Проверьте, что приложение запущено и пишет в файл:
```bash
ps aux | grep "go run\|./app"
tail -f ../logs/app.log
```

3. Проверьте, что Promtail запущен:
```bash
cd ..
docker-compose ps promtail
```

4. Проверьте логи Promtail:
```bash
docker-compose logs promtail
```

### Приложение не запускается в фоне

```bash
# Используйте nohup для стабильного запуска в фоне
nohup go run main.go > ../logs/app.log 2>&1 &

# Или соберите бинарник и запустите его
go build -o app
nohup ./app > ../logs/app.log 2>&1 &

# Проверьте процесс
ps aux | grep app
```

### Хочу использовать systemd (Linux)

Создайте файл `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=My Go Application
After=network.target

[Service]
Type=simple
User=myuser
WorkingDirectory=/path/to/monitoring/go-demo
ExecStart=/path/to/monitoring/go-demo/app
StandardOutput=file:/path/to/monitoring/logs/app.log
StandardError=file:/path/to/monitoring/logs/app.log
Restart=always

[Install]
WantedBy=multi-user.target
```

Затем:
```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
sudo systemctl status myapp
```

## Дополнительные примеры

Посмотрите код в `main.go` для примеров:
- Базовое использование
- Сервисы с контекстными полями
- Наследование контекста
- Транзакции с вложенным контекстом
- Сложные структурированные данные
