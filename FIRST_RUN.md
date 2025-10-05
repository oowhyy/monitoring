# 🎬 Гайд первого запуска

Пошаговая инструкция для самого первого запуска системы мониторинга.

---

## ✅ Шаг 1: Проверка предварительных требований

### Проверьте, что у вас установлено:

```bash
# Docker
docker --version
# Должно быть: Docker version 20.10.0 или выше

# Docker Compose
docker-compose --version
# Должно быть: Docker Compose version 1.29.0 или выше
```

❌ Если команды не найдены, установите Docker:
- **MacOS**: https://docs.docker.com/desktop/install/mac-install/
- **Linux**: https://docs.docker.com/engine/install/
- **Windows**: https://docs.docker.com/desktop/install/windows-install/

---

## ✅ Шаг 2: Перейдите в директорию проекта

```bash
cd /Users/vshahrai/personal/monitoring
```

Или укажите свой путь к проекту.

---

## ✅ Шаг 3: Проверьте структуру проекта

```bash
ls -la
```

Вы должны увидеть:
- ✅ `docker-compose.yml`
- ✅ `.env` или `.env.example`
- ✅ `config/` директория
- ✅ `Makefile`

---

## ✅ Шаг 4: Настройка переменных окружения (опционально)

Если хотите изменить порты или пути:

```bash
# Скопируйте пример (если .env не существует)
cp .env.example .env

# Отредактируйте по необходимости
nano .env
# или
vim .env
```

**Что можно изменить:**
- `GRAFANA_PORT=3000` - порт Grafana (если 3000 занят)
- `LOKI_PORT=3100` - порт Loki (если 3100 занят)
- `LOG_SOURCE_PATH=./logs` - откуда брать логи

По умолчанию всё уже настроено и работает!

---

## ✅ Шаг 5: Создайте необходимые директории

### Вариант A: Используя Makefile (рекомендуется)

```bash
make setup
```

Эта команда создаст `.env` файл с настройками по умолчанию

### Вариант B: Вручную

```bash
# Скопируйте пример
cp .env.example .env

# Отредактируйте при необходимости
nano .env
```

---

## ✅ Шаг 6: Запустите систему

### Вариант A: Используя Makefile (рекомендуется)

```bash
make start
```

### Вариант B: Используя Docker Compose

```bash
docker-compose up -d
```

**Что происходит:**
- 🔄 Docker скачивает образы (при первом запуске, ~5 минут)
- 🚀 Запускаются 3 контейнера: Loki, Promtail, Grafana
- ✅ Система готова к работе!

**Вывод должен быть примерно таким:**
```
Creating network "monitoring_monitoring" with driver "bridge"
Creating loki      ... done
Creating promtail  ... done
Creating grafana   ... done
```

---

## ✅ Шаг 7: Проверьте статус

```bash
make status
# или
docker-compose ps
```

**Все контейнеры должны быть "Up":**
```
   Name                 Command               State           Ports         
-----------------------------------------------------------------------------
grafana     /run.sh                          Up      0.0.0.0:3000->3000/tcp
loki        /usr/bin/loki -config.file...   Up      0.0.0.0:3100->3100/tcp
promtail    /usr/bin/promtail -config....   Up      
```

❌ Если что-то "Exit" или "Restarting":
```bash
# Смотрим логи проблемного контейнера
docker-compose logs grafana
docker-compose logs loki
docker-compose logs promtail
```

---

## ✅ Шаг 8: Откройте Grafana

Откройте браузер и перейдите на:

```
http://localhost:3000
```

(Или другой порт, если вы изменили `GRAFANA_PORT`)

**Страница входа:**
- 👤 **Username**: `admin`
- 🔑 **Password**: `admin`

При первом входе Grafana предложит изменить пароль:
- Можете изменить
- Или нажать "Skip" (для локальной разработки)

---

## ✅ Шаг 9: Проверьте дашборд

После входа в Grafana:

1. Нажмите на **☰** (меню) слева вверху
2. Выберите **Dashboards**
3. Откройте папку **Logs**
4. Кликните на **Go Application Logs**

**Вы увидите дашборд!** 🎉

На данный момент он может быть пустым - это нормально, логов еще нет.

---

## ✅ Шаг 10: Создайте тестовые логи

### Вариант A: Используя Makefile (рекомендуется)

```bash
make test-logs
```

Эта команда запустит демо Go приложение, которое будет писать логи.

### Вариант B: Запустите вручную

```bash
mkdir -p logs
cd go-demo
go run main.go > ../logs/app.log 2>&1 &
cd ..

# Проверьте, что логи пишутся
tail -f logs/app.log
# Нажмите Ctrl+C чтобы выйти
```

---

## ✅ Шаг 11: Проверьте логи в Grafana

**Подождите 5-10 секунд** (Promtail читает файл и отправляет в Loki)

Вернитесь в дашборд Grafana:
- Обновите страницу (F5)
- Измените временной диапазон на "Last 5 minutes" (справа вверху)

**Вы должны увидеть логи!** 🎊

На дашборде появятся:
- 📊 График по уровням
- 🔢 Статистика (ошибки, предупреждения)
- 📝 Список логов внизу

---

## ✅ Шаг 12: Поэкспериментируйте

### Explore функция

1. В меню слева выберите **Explore** (🔍 иконка)
2. В datasource выберите **Loki**
3. Попробуйте запросы:

```logql
{job="go-application"}
```

```logql
{job="go-application", level="error"}
```

```logql
{job="go-application"} |= "warning"
```

### Фильтры на дашборде

На дашборде вверху есть фильтры:
- **Job** - источник логов
- **Log Level** - уровень (All, error, warn, info, debug)

Попробуйте выбрать только "error" - дашборд обновится!

---

## ✅ Шаг 13: Запустите свое приложение

Любое приложение, которое пишет JSON логи в stdout, подойдет:

```bash
# Go приложение (из примера)
cd go-demo
go run main.go > ../logs/app.log 2>&1 &

# Или ваше приложение на любом языке
./your-app > logs/app.log 2>&1 &

# Python
python3 your-app.py > logs/app.log 2>&1 &

# Node.js
node your-app.js > logs/app.log 2>&1 &
```

Приложение:
- Пишет логи в stdout
- Вы перенаправляете в файл через `> logs/app.log`
- Promtail читает файл и отправляет в Loki
- Логи автоматически появятся в Grafana

---

## 🎉 Готово!

Поздравляем! Ваша система мониторинга работает!

---

## 🔍 Что дальше?

### Для изучения:

1. **README.md** - полная документация
2. **LOGQL_EXAMPLES.md** - примеры запросов
3. **ARCHITECTURE.md** - как всё устроено
4. **go-demo/README.md** - интеграция с приложением

### Для работы:

```bash
make help        # Список всех команд
make status      # Проверка статуса
make logs        # Просмотр логов системы
make stop        # Остановка
make restart     # Перезапуск
```

---

## ❌ Устранение проблем

### Проблема: Контейнеры не запускаются

```bash
# Проверьте логи
docker-compose logs

# Проверьте порты
lsof -i :3000
lsof -i :3100

# Если порты заняты, измените их в .env
```

### Проблема: Grafana не показывает логи

```bash
# Проверьте, что Promtail работает
docker-compose logs promtail

# Проверьте, что файлы логов существуют
ls -la logs/

# Проверьте Loki
curl http://localhost:3100/ready
# Должно вернуть "ready"

# Проверьте метки в Loki
curl http://localhost:3100/loki/api/v1/labels
```

### Проблема: Permission denied

```bash
# Дайте права на директории
chmod -R 777 data logs

# Или более безопасно:
sudo chown -R 472:472 data/grafana
```

### Полная диагностика

```bash
./scripts/check-system.sh
```

Этот скрипт проверит всё и покажет, что не работает.

---

## 🛑 Остановка системы

### Временная остановка (сохраняет данные)

```bash
make stop
# или
docker-compose down
```

### Полная очистка (удаляет все данные)

```bash
make clean
# или
docker-compose down -v
rm -rf data/*
```

---

## 🔄 Обновление системы

```bash
# Скачать новые версии образов
make update
# или
docker-compose pull

# Перезапустить с новыми версиями
make restart
```

---

## 📞 Помощь

Если что-то не работает:

1. Проверьте **README.md** → раздел **Troubleshooting**
2. Запустите `./scripts/check-system.sh`
3. Посмотрите логи: `docker-compose logs`
4. Проверьте официальную документацию

---

**Приятного использования!** 🚀
