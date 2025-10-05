# 🏗️ Архитектура системы мониторинга

Подробное описание архитектуры и компонентов системы.

## 📊 Общая схема

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST SYSTEM                              │
│                                                                   │
│  ┌──────────────┐                                                │
│  │ Go Application│                                               │
│  │  (Zap Logger) │                                               │
│  └───────┬───────┘                                               │
│          │ writes JSON logs                                      │
│          ▼                                                        │
│  ┌──────────────┐                                                │
│  │  logs/*.log  │ (mounted volume)                              │
│  └──────┬───────┘                                                │
│         │                                                         │
│  ┌──────┴───────────────────────────────────────────────┐       │
│  │              DOCKER ENVIRONMENT                       │       │
│  │                                                        │       │
│  │  ┌─────────────┐         ┌──────────────┐            │       │
│  │  │  Promtail   │────────▶│     Loki     │            │       │
│  │  │  (Collector)│  push   │  (Storage)   │            │       │
│  │  │  :9080      │  logs   │  :3100       │            │       │
│  │  └─────────────┘         └──────┬───────┘            │       │
│  │         │                        │                     │       │
│  │         │ reads                  │ queries             │       │
│  │         │ logs                   │                     │       │
│  │         │                        │                     │       │
│  │         │                        ▼                     │       │
│  │  ┌──────▼──────────────┐  ┌──────────────┐           │       │
│  │  │   logs/ (volume)    │  │   Grafana    │           │       │
│  │  │                     │  │     (UI)     │           │       │
│  │  └─────────────────────┘  │   :3000      │◀──────────┼───────┤
│  │                            └──────────────┘   HTTP    │       │
│  │                                                        │       │
│  │  ┌─────────────────────────────────────────┐         │       │
│  │  │        Docker Network: monitoring        │         │       │
│  │  └─────────────────────────────────────────┘         │       │
│  └────────────────────────────────────────────────────────      │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Persistent Storage (Docker Volumes)          │    │
│  │  ┌──────────────────────────┐  ┌─────────────────────┐│    │
│  │  │ Volume: loki-data        │  │ Volume:             ││    │
│  │  │   - chunks               │  │   grafana-data      ││    │
│  │  │   - indexes              │  │   - dashboards      ││    │
│  │  └──────────────────────────┘  └─────────────────────┘│    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

         User accesses via browser: http://localhost:3000
```

## 🧩 Компоненты

### 1. Promtail (Log Collector Agent)

**Назначение:** Сбор логов из файлов и отправка в Loki

**Характеристики:**
- Образ: `grafana/promtail:2.9.3`
- Порт: 9080 (внутренний, для метрик)
- Конфигурация: `config/promtail.yml`

**Основные функции:**
- Чтение лог-файлов в реальном времени
- Парсинг JSON формата
- Извлечение и индексация меток (labels)
- Буферизация и batch отправка в Loki
- Отслеживание позиции чтения (positions.yaml)

**Pipeline обработки:**
```
1. Read file → 2. Parse JSON → 3. Extract labels → 
4. Add metadata → 5. Batch → 6. Send to Loki
```

**Важные параметры:**
- `batchwait`: 1s - время ожидания перед отправкой
- `batchsize`: 1MB - размер батча
- `positions`: отслеживание позиции в файле

---

### 2. Loki (Log Aggregation System)

**Назначение:** Хранение, индексация и предоставление доступа к логам

**Характеристики:**
- Образ: `grafana/loki:2.9.3`
- Порт: 3100 (HTTP API)
- Конфигурация: `config/loki.yml`
- Хранилище: Docker volume (настраивается в .env)

**Основные функции:**
- Прием логов от Promtail
- Индексация по меткам (labels)
- Сжатие и хранение логов
- Обработка LogQL запросов
- Retention management (удаление старых данных)

**Структура хранилища:**
```
/var/lib/docker/volumes/loki-data/_data/
├── chunks/              # Сжатые логи
├── boltdb-shipper-*/    # Индексы
└── rules/               # Правила алертов
```

**Retention Policy:**
- По умолчанию: 30 дней
- Настраивается в `loki.yml`
- Автоматическое удаление старых данных

**API Endpoints:**
- `GET /ready` - проверка готовности
- `GET /metrics` - метрики Prometheus
- `POST /loki/api/v1/push` - прием логов
- `GET /loki/api/v1/query` - запрос логов
- `GET /loki/api/v1/query_range` - запрос за период
- `GET /loki/api/v1/labels` - получение меток

---

### 3. Grafana (Visualization Platform)

**Назначение:** Визуализация логов, создание дашбордов, алертинг

**Характеристики:**
- Образ: `grafana/grafana:10.2.3`
- Порт: 3000 (HTTP UI)
- Хранилище: Docker volume (настраивается в .env)
- Provisioning: `config/grafana/provisioning/`

**Основные функции:**
- Web-интерфейс для просмотра логов
- Создание и управление дашбордами
- Выполнение LogQL запросов
- Алертинг и уведомления
- Управление пользователями и правами

**Infrastructure as Code:**
Все настройки прописаны в конфигах:
- Datasource: автоматически настроен Loki
- Dashboard: предустановленный дашборд
- Не требует ручной настройки после запуска

**Структура provisioning:**
```
config/grafana/provisioning/
├── datasources/
│   └── loki.yml          # Автоматическая настройка Loki
└── dashboards/
    ├── dashboard.yml     # Настройка провайдера
    └── definitions/
        └── go-application-logs.json  # Готовый дашборд
```

---

## 🔄 Поток данных

### 1. Генерация логов

```go
logger.Info("User action",
    zap.String("user_id", "123"),
    zap.String("action", "login"),
)
```

### 2. Запись в файл

```json
{"level":"info","ts":"2024-01-01T12:00:00Z","msg":"User action","user_id":"123","action":"login"}
```

Лог записывается в `logs/app.log`

### 3. Чтение Promtail

- Promtail следит за файлом через inotify (Linux) или polling
- Читает новые строки
- Парсит JSON

### 4. Обработка Pipeline

```yaml
pipeline_stages:
  - json:              # Парсинг JSON
      expressions:
        level: level
        message: msg
  - labels:            # Создание меток для индексации
      level:
  - timestamp:         # Извлечение timestamp
      source: timestamp
  - output:            # Формирование финального сообщения
      source: message
```

### 5. Отправка в Loki

- Батчируется (по умолчанию 1 сек или 1MB)
- Отправляется POST на `http://loki:3100/loki/api/v1/push`
- Сжимается snappy

### 6. Хранение в Loki

- Индексируются метки (labels)
- Логи сжимаются и пишутся в chunks
- Создается индекс для быстрого поиска

### 7. Запрос из Grafana

```logql
{job="go-application", level="error"} [5m]
```

- Grafana отправляет LogQL запрос
- Loki ищет по индексу
- Возвращает результаты
- Grafana визуализирует

---

## 🗄️ Хранение данных

### Персистентные данные

Все данные хранятся на хосте и переживают перезапуск контейнеров:

```
monitoring/
├── logs/                  # Исходные лог-файлы приложений
│   └── app.log
└── config/                # Конфигурационные файлы

Docker volumes (по умолчанию в /var/lib/docker/volumes/):
├── loki-data/_data/       # Данные Loki
│   ├── chunks/            # Сжатые логи (основное хранилище)
│   ├── boltdb-*/          # Индексы BoltDB
│   └── rules/             # Правила алертов
└── grafana-data/_data/    # Данные Grafana
    ├── grafana.db         # SQLite база с настройками
    ├── plugins/           # Установленные плагины
    └── png/               # Кэш изображений
```

### Оценка размера данных

**Для среднего приложения (1000 логов/сек):**

| Компонент | Размер в день | Размер в месяц |
|-----------|---------------|----------------|
| Сырые логи | ~500 MB | ~15 GB |
| Loki chunks (сжатые) | ~50 MB | ~1.5 GB |
| Loki indexes | ~10 MB | ~300 MB |
| Grafana DB | ~50 MB | ~500 MB |
| **Итого** | **~610 MB** | **~17.3 GB** |

**С retention 30 дней: ~17-20 GB**

---

## 🔒 Безопасность

### Текущая конфигурация (Development)

⚠️ **НЕ ДЛЯ ПРОДАКШЕНА:**
- Дефолтные пароли (admin/admin)
- Нет TLS/HTTPS
- Нет аутентификации между сервисами
- Все порты доступны локально

### Рекомендации для Production

1. **Grafana:**
   - Измените пароль администратора
   - Настройте OAuth/LDAP
   - Включите HTTPS
   - Используйте внешнюю БД (PostgreSQL)

2. **Loki:**
   - Включите аутентификацию (`auth_enabled: true`)
   - Настройте tenant ID
   - Используйте reverse proxy (nginx)

3. **Promtail:**
   - Используйте TLS для коммуникации с Loki
   - Ограничьте доступ к лог-файлам

4. **Network:**
   - Изолируйте Docker network
   - Используйте firewall
   - Настройте VPN для удаленного доступа

---

## 📊 Производительность

### Ресурсы

**Минимальные требования:**
- CPU: 2 ядра
- RAM: 2 GB
- Disk: 10 GB (для логов)

**Рекомендуемые:**
- CPU: 4 ядра
- RAM: 8 GB
- Disk: 100 GB SSD
- Network: 100 Mbps

### Лимиты (по умолчанию)

**Loki:**
- `ingestion_rate_mb`: 10 MB/s на tenant
- `ingestion_burst_size_mb`: 20 MB
- `max_query_series`: 1000
- `max_entries_limit_per_query`: 10000

**Promtail:**
- `batchsize`: 1 MB
- `batchwait`: 1s
- Нет ограничений на чтение файлов

### Оптимизация

1. **Используйте эффективные метки:**
   - Не создавайте метки с высокой кардинальностью
   - ✅ Хорошо: `level`, `service`, `environment`
   - ❌ Плохо: `user_id`, `request_id`, `timestamp`

2. **Настройте retention:**
   ```yaml
   retention_period: 168h  # 7 дней вместо 30
   ```

3. **Используйте компакцию:**
   ```yaml
   compactor:
     retention_enabled: true
     compaction_interval: 10m
   ```

4. **Кэширование:**
   ```yaml
   query_range:
     results_cache:
       cache:
         embedded_cache:
           max_size_mb: 100
   ```

---

## 🔧 Масштабирование

### Горизонтальное масштабирование Loki

Для больших объемов логов можно использовать микросервисную архитектуру:

```
Ingester ──┐
Ingester ──┼─→ Storage (S3/GCS)
Ingester ──┘

Querier ───┐
Querier ───┼─→ Query Frontend
Querier ───┘
```

### Распределенная система

```yaml
# docker-compose.yml для кластера
services:
  loki-write:
    # Только запись
  loki-read:
    # Только чтение
  loki-compactor:
    # Компакция и удаление
```

Документация: https://grafana.com/docs/loki/latest/fundamentals/architecture/

---

## 🔍 Мониторинг самой системы

### Метрики

Все компоненты экспортируют метрики Prometheus:

- **Loki**: `http://localhost:3100/metrics`
- **Promtail**: `http://localhost:9080/metrics`
- **Grafana**: `http://localhost:3000/metrics`

### Полезные метрики

**Loki:**
- `loki_ingester_chunks_created_total` - создано чанков
- `loki_ingester_received_chunks` - получено чанков
- `loki_request_duration_seconds` - latency запросов

**Promtail:**
- `promtail_read_bytes_total` - прочитано байт
- `promtail_sent_entries_total` - отправлено записей
- `promtail_dropped_entries_total` - отброшено записей

---

## 📚 Дополнительные материалы

- [Официальная документация Loki](https://grafana.com/docs/loki/latest/)
- [Best Practices](https://grafana.com/docs/loki/latest/best-practices/)
- [Troubleshooting Guide](https://grafana.com/docs/loki/latest/operations/troubleshooting/)
- [Scaling Loki](https://grafana.com/docs/loki/latest/fundamentals/architecture/)
