# 📚 Примеры LogQL запросов

Коллекция полезных LogQL запросов для работы с логами в Grafana/Loki.

## 📖 Оглавление

- [Базовые запросы](#базовые-запросы)
- [Фильтрация](#фильтрация)
- [Парсинг JSON](#парсинг-json)
- [Агрегация и подсчет](#агрегация-и-подсчет)
- [Метрики из логов](#метрики-из-логов)
- [Сложные запросы](#сложные-запросы)
- [Полезные паттерны](#полезные-паттерны)

---

## Базовые запросы

### Все логи приложения

```logql
{job="go-application"}
```

### Логи определенного уровня

```logql
{job="go-application", level="error"}
{job="go-application", level="warn"}
{job="go-application", level="info"}
```

### Логи за последние 5 минут

```logql
{job="go-application"} [5m]
```

### Последние 100 логов

```logql
{job="go-application"} | limit 100
```

---

## Фильтрация

### Поиск по тексту (contains)

```logql
{job="go-application"} |= "database"
```

### Исключение определенного текста

```logql
{job="go-application"} != "health check"
```

### Поиск по регулярному выражению

```logql
{job="go-application"} |~ "error|exception|failed"
```

### Исключение по регулярному выражению

```logql
{job="go-application"} !~ "debug|trace"
```

### Цепочка фильтров

```logql
{job="go-application"} 
  |= "user" 
  |= "login" 
  != "logout"
```

### Case-insensitive поиск

```logql
{job="go-application"} |~ "(?i)error"
```

---

## Парсинг JSON

### Извлечение полей из JSON

```logql
{job="go-application"} 
  | json
  | user_id != ""
```

### Извлечение конкретных полей

```logql
{job="go-application"} 
  | json user_id, request_id, duration_ms
```

### Фильтрация по значению JSON поля

```logql
{job="go-application"} 
  | json 
  | user_id = "user123"
```

### Фильтрация по числовому полю

```logql
{job="go-application"} 
  | json 
  | duration_ms > 1000
```

### Фильтрация по вложенному полю

```logql
{job="go-application"} 
  | json 
  | metadata_user_email =~ ".*@example.com"
```

---

## Агрегация и подсчет

### Подсчет логов за интервал

```logql
count_over_time({job="go-application"} [5m])
```

### Подсчет ошибок за интервал

```logql
count_over_time({job="go-application", level="error"} [5m])
```

### Суммирование по меткам

```logql
sum by (level) (
  count_over_time({job="go-application"} [5m])
)
```

### Rate (логов в секунду)

```logql
rate({job="go-application"} [5m])
```

### Rate только ошибок

```logql
rate({job="go-application", level="error"} [1m])
```

---

## Метрики из логов

### Среднее время выполнения

```logql
avg_over_time(
  {job="go-application"} 
    | json 
    | unwrap duration_ms [5m]
)
```

### Максимальное время выполнения

```logql
max_over_time(
  {job="go-application"} 
    | json 
    | unwrap duration_ms [5m]
)
```

### Percentile (95th)

```logql
quantile_over_time(0.95, 
  {job="go-application"} 
    | json 
    | unwrap duration_ms [5m]
)
```

### Сумма значений

```logql
sum_over_time(
  {job="go-application"} 
    | json 
    | unwrap bytes_sent [5m]
)
```

---

## Сложные запросы

### Топ-10 пользователей с ошибками

```logql
topk(10, 
  sum by (user_id) (
    count_over_time(
      {job="go-application", level="error"} 
        | json 
        | user_id != "" [1h]
    )
  )
)
```

### Топ-5 самых медленных операций

```logql
topk(5, 
  avg by (operation) (
    avg_over_time(
      {job="go-application"} 
        | json 
        | unwrap duration_ms [5m]
    )
  )
)
```

### Процент ошибок от общего числа логов

```logql
(
  sum(count_over_time({job="go-application", level="error"} [5m]))
  /
  sum(count_over_time({job="go-application"} [5m]))
) * 100
```

### Логи, где длительность превышает порог

```logql
{job="go-application"} 
  | json 
  | duration_ms > 1000
```

### Группировка ошибок по типу

```logql
sum by (error) (
  count_over_time(
    {job="go-application", level="error"} 
      | json 
      | error != "" [1h]
  )
)
```

---

## Полезные паттерны

### Мониторинг здоровья приложения

**Ошибки за последние 5 минут:**
```logql
sum(count_over_time({job="go-application", level="error"} [5m]))
```

**Предупреждения за последние 5 минут:**
```logql
sum(count_over_time({job="go-application", level="warn"} [5m]))
```

**Общее количество логов:**
```logql
sum(rate({job="go-application"} [1m]))
```

### Поиск конкретных проблем

**Ошибки подключения к БД:**
```logql
{job="go-application", level="error"} 
  |~ "database|connection|sql"
```

**Таймауты:**
```logql
{job="go-application"} 
  |~ "timeout|timed out|deadline exceeded"
```

**Проблемы с памятью:**
```logql
{job="go-application"} 
  |~ "out of memory|memory|OOM"
```

**Проблемы с аутентификацией:**
```logql
{job="go-application"} 
  |~ "authentication|unauthorized|forbidden|401|403"
```

### Анализ производительности

**Медленные запросы (> 1 секунда):**
```logql
{job="go-application"} 
  | json 
  | duration_ms > 1000
```

**Средняя задержка по эндпоинтам:**
```logql
avg by (endpoint) (
  avg_over_time(
    {job="go-application"} 
      | json 
      | unwrap duration_ms [5m]
  )
)
```

**Распределение времени ответа:**
```logql
histogram_over_time(
  {job="go-application"} 
    | json 
    | unwrap duration_ms [5m]
)
```

### Анализ пользовательской активности

**Количество активных пользователей:**
```logql
count(
  count by (user_id) (
    {job="go-application"} 
      | json 
      | user_id != "" [5m]
  )
)
```

**Активность по пользователям:**
```logql
sum by (user_id) (
  count_over_time(
    {job="go-application"} 
      | json 
      | user_id != "" [1h]
  )
)
```

**Логины пользователей:**
```logql
{job="go-application"} 
  |= "login" 
  | json 
  | user_id != ""
```

### Бизнес-метрики

**Количество созданных заказов:**
```logql
sum(
  count_over_time(
    {job="go-application"} 
      |= "order created" [1h]
  )
)
```

**Количество платежей:**
```logql
sum(
  count_over_time(
    {job="go-application"} 
      |= "payment processed" [1h]
  )
)
```

**Конверсия (пример):**
```logql
(
  sum(count_over_time({job="go-application"} |= "checkout completed" [1h]))
  /
  sum(count_over_time({job="go-application"} |= "checkout started" [1h]))
) * 100
```

---

## Советы по оптимизации запросов

### 1. Используйте метки (labels)

**Плохо (медленно):**
```logql
{job="go-application"} |= "error"
```

**Хорошо (быстро):**
```logql
{job="go-application", level="error"}
```

### 2. Ограничивайте временной диапазон

**Плохо:**
```logql
{job="go-application"} [7d]  # Сканирует 7 дней
```

**Хорошо:**
```logql
{job="go-application"} [1h]  # Сканирует только 1 час
```

### 3. Используйте специфичные фильтры

**Плохо:**
```logql
{job="go-application"} |~ ".*user.*"
```

**Хорошо:**
```logql
{job="go-application"} |= "user" | json | user_id != ""
```

### 4. Агрегируйте, не показывайте сырые логи

**Плохо (для больших объемов):**
```logql
{job="go-application"}  # Возвращает все логи
```

**Хорошо:**
```logql
sum by (level) (count_over_time({job="go-application"} [5m]))
```

---

## Полезные ссылки

- **LogQL Syntax**: https://grafana.com/docs/loki/latest/logql/
- **Log queries**: https://grafana.com/docs/loki/latest/logql/log_queries/
- **Metric queries**: https://grafana.com/docs/loki/latest/logql/metric_queries/
- **Template functions**: https://grafana.com/docs/loki/latest/logql/template_functions/

---

## Тестирование запросов

Все эти запросы можно протестировать в Grafana:

1. Откройте **Explore** (слева в меню)
2. Выберите **Loki** как datasource
3. Вставьте запрос
4. Нажмите **Run query**

Или прямо в API:

```bash
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="go-application"}'
```
