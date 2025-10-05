# 📚 Индекс документации

Добро пожаловать в систему мониторинга логов на базе Promtail, Loki и Grafana!

---

## 🚀 Начало работы

### Для новичков

1. **[FIRST_RUN.md](FIRST_RUN.md)** - Пошаговый гайд первого запуска
   - Проверка требований
   - Установка и настройка
   - Первый запуск и проверка

2. **[QUICKSTART.md](QUICKSTART.md)** - Быстрый старт за 3 шага
   - Для тех, кто уже знаком с Docker
   - 3 команды до запуска
   - Минимум текста, максимум действий

### Для всех

3. **[README.md](README.md)** - Главная документация (⭐ НАЧНИТЕ ОТСЮДА)
   - Полное руководство
   - Установка с нуля для разных ОС
   - Конфигурация и настройка
   - Использование Grafana
   - Troubleshooting
   - FAQ

---

## 📖 Подробная документация

### Архитектура и устройство

4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Архитектура системы
   - Схема и компоненты
   - Поток данных
   - Производительность
   - Масштабирование
   - Для DevOps/SRE

5. **[SUMMARY.md](SUMMARY.md)** - Сводка по проекту
   - Что создано
   - Структура проекта
   - Реализованные требования
   - Быстрый обзор возможностей

### Работа с логами

6. **[LOGQL_EXAMPLES.md](LOGQL_EXAMPLES.md)** - Примеры LogQL запросов
   - 30+ готовых примеров
   - Базовые и продвинутые запросы
   - Фильтрация и агрегация
   - Метрики из логов
   - Практические паттерны

### Интеграция с приложением

7. **[go-demo/README.md](go-demo/README.md)** - Интеграция Go + Zap
   - Настройка Zap logger
   - Правильный формат логов
   - Примеры использования
   - Структурированное логирование

---

## 🛠️ Инструменты и скрипты

### Makefile команды

```bash
make help        # Показать все доступные команды
make setup       # Первоначальная настройка
make start       # Запустить систему
make stop        # Остановить систему
make restart     # Перезапустить систему
make status      # Проверить статус сервисов
make logs        # Просмотреть логи
make test-logs   # Создать тестовые логи
make clean       # Очистить все данные
make update      # Обновить Docker образы
make backup      # Создать backup
make check       # Проверить конфигурацию
```

### Bash скрипты

**[scripts/check-system.sh](scripts/check-system.sh)** - Проверка работоспособности системы
```bash
# Полная диагностика
./scripts/check-system.sh
```

---

## 📂 Структура проекта

```
monitoring/
├── 📖 INDEX.md                    ← Вы здесь
├── 📘 README.md                   ← Главная документация (начните отсюда)
├── 🚀 QUICKSTART.md               ← Быстрый старт
├── 🎬 FIRST_RUN.md                ← Гайд первого запуска
├── 🏗️  ARCHITECTURE.md            ← Архитектура системы
├── 📊 LOGQL_EXAMPLES.md           ← Примеры запросов
├── 📦 SUMMARY.md                  ← Сводка по проекту
│
├── 🐳 docker-compose.yml          ← Основной файл запуска
├── ⚙️  .env                        ← Переменные окружения
├── 📝 .env.example                ← Пример переменных
├── 🔨 Makefile                    ← Удобные команды
├── 🚫 .gitignore                  ← Git ignore
│
├── 📁 config/                     ← Конфигурационные файлы
│   ├── loki-config.yml           ← Конфигурация Loki
│   ├── promtail-config.yml       ← Конфигурация Promtail
│   └── grafana/
│       └── provisioning/
│           ├── datasources/      ← Автонастройка Loki
│           └── dashboards/       ← Готовые дашборды
│
├── 📁 scripts/                    ← Вспомогательные скрипты
│   └── check-system.sh           ← Проверка работоспособности
│
├── 📁 go-demo/                    ← Пример Go приложения
│   ├── main.go                   ← Демо с Zap logger
│   └── README.md                 ← Документация Go приложения
│
├── 📁 data/                       ← Персистентное хранилище (создается автоматически)
│   ├── loki/                     ← Данные Loki
│   └── grafana/                  ← Данные Grafana
│
└── 📁 logs/                       ← Логи вашего приложения
    └── *.log
```

---

## 🎯 Быстрые ссылки

### Внутренние ресурсы

| Что нужно | Где найти |
|-----------|-----------|
| 🚀 **Первый запуск** | [FIRST_RUN.md](FIRST_RUN.md) |
| 📖 **Полная документация** | [README.md](README.md) |
| 🔍 **Примеры запросов** | [LOGQL_EXAMPLES.md](LOGQL_EXAMPLES.md) |
| 🛠️ **Настройка Go** | [go-demo/README.md](go-demo/README.md) |
| 🏗️ **Как работает** | [ARCHITECTURE.md](ARCHITECTURE.md) |
| ❓ **FAQ** | [README.md#FAQ](README.md#-faq) |
| 🔧 **Troubleshooting** | [README.md#Troubleshooting](README.md#-troubleshooting) |

### Веб-интерфейсы

После запуска системы:

- 🎨 **Grafana UI**: http://localhost:3000 (admin/admin)
- 🔌 **Loki API**: http://localhost:3100
- 📊 **Loki Ready**: http://localhost:3100/ready
- 📈 **Loki Metrics**: http://localhost:3100/metrics

### Официальная документация

| Компонент | Документация |
|-----------|--------------|
| **Loki** | https://grafana.com/docs/loki/latest/ |
| **Promtail** | https://grafana.com/docs/loki/latest/clients/promtail/ |
| **Grafana** | https://grafana.com/docs/grafana/latest/ |
| **LogQL** | https://grafana.com/docs/loki/latest/logql/ |
| **Zap Logger** | https://pkg.go.dev/go.uber.org/zap |

---

## 🎓 Обучение

### Для начинающих

1. Прочитайте [FIRST_RUN.md](FIRST_RUN.md)
2. Запустите систему по инструкции
3. Создайте тестовые логи: `make test-logs`
4. Откройте Grafana и изучите дашборд
5. Попробуйте примеры из [LOGQL_EXAMPLES.md](LOGQL_EXAMPLES.md)

### Для разработчиков

1. Изучите [go-demo/README.md](go-demo/README.md)
2. Настройте логирование в своем приложении
3. Запустите приложение и проверьте логи в Grafana
4. Создайте свои дашборды
5. Прочитайте [LOGQL_EXAMPLES.md](LOGQL_EXAMPLES.md) для продвинутых запросов

### Для DevOps/SRE

1. Изучите [ARCHITECTURE.md](ARCHITECTURE.md)
2. Прочитайте раздел "Production" в [README.md](README.md)
3. Настройте retention и limits
4. Настройте алерты
5. Интегрируйте с другими системами мониторинга

---

## ⚡ Быстрый старт (TL;DR)

```bash
# 1. Подготовка
make setup

# 2. Запуск
make start

# 3. Тестирование
make test-logs

# 4. Откройте Grafana
open http://localhost:3000
# Логин: admin, Пароль: admin
```

---

## 📞 Помощь

### Проблемы с запуском?

1. ✅ Проверьте [FIRST_RUN.md](FIRST_RUN.md) - пошаговая инструкция
2. ✅ Запустите диагностику: `./scripts/check-system.sh`
3. ✅ Посмотрите [Troubleshooting в README.md](README.md#-troubleshooting)
4. ✅ Проверьте логи: `docker-compose logs`

### Вопросы по использованию?

1. ✅ Прочитайте [README.md](README.md) - там 99% ответов
2. ✅ Изучите [FAQ в README.md](README.md#-faq)
3. ✅ Посмотрите примеры в [LOGQL_EXAMPLES.md](LOGQL_EXAMPLES.md)
4. ✅ Проверьте официальную документацию (ссылки выше)

### Хотите углубиться?

1. 📚 [ARCHITECTURE.md](ARCHITECTURE.md) - подробно об устройстве
2. 📚 [Официальные туториалы Grafana](https://grafana.com/tutorials/)
3. 📚 [Loki Best Practices](https://grafana.com/docs/loki/latest/best-practices/)
4. 📚 [Grafana Community](https://community.grafana.com/)

---

## 🎁 Что включено

- ✅ Docker Compose конфигурация
- ✅ Готовые конфиги для Loki, Promtail, Grafana
- ✅ Предустановленный дашборд
- ✅ Infrastructure as Code подход
- ✅ Пример Go приложения с правильным логированием
- ✅ Скрипты для тестирования и диагностики
- ✅ Makefile с удобными командами
- ✅ Подробная документация на русском языке
- ✅ 30+ примеров LogQL запросов
- ✅ Troubleshooting гайд
- ✅ FAQ

---

## 🌟 Преимущества

- 🚀 **Быстрый старт** - 3 команды до запуска
- 📦 **Всё в одном** - единый docker-compose файл
- ⚙️ **Настраиваемость** - всё через .env файл
- 🔒 **Персистентность** - данные сохраняются
- 📊 **Готовый дашборд** - не нужно настраивать вручную
- 🛠️ **IaC подход** - всё как код, можно версионировать
- 📚 **Документация** - подробная на русском языке
- 🎓 **Примеры** - Go приложение, LogQL запросы

---

## 📊 Статистика проекта

- **Файлов документации**: 8
- **Конфигурационных файлов**: 5
- **Bash скриптов**: 2
- **Примеров LogQL**: 30+
- **Makefile команд**: 12
- **Строк кода**: 2000+
- **Строк документации**: 3000+

---

## 🎉 Начните сейчас!

### Вариант 1: Я новичок

👉 Начните с [FIRST_RUN.md](FIRST_RUN.md)

### Вариант 2: Я знаю Docker

👉 Начните с [QUICKSTART.md](QUICKSTART.md)

### Вариант 3: Хочу всё понять

👉 Начните с [README.md](README.md)

---

**Удачи в мониторинге логов!** 🚀📊🎯
