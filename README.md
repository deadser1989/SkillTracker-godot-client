SkillTracker

Геймифицированный трекер навыков и привычек. Клиентская часть реализована на движке Godot, логика расчета прогресса навыков вынесена в C++ (GDExtension) для оптимизации. Бэкенд включает интеграцию со Strava API для автоматического импорта физической активности пользователя.

Структура репозитория

1) `/app` — исходный код серверной части (бэкенд) и обработка данных Strava.
2) `/game` — клиентский проект Godot (UI, GDScript, `main.gd`).
3)`/src` — исходники C++ (GDExtension), включающие математику прокачки (уровни, прогресс, парсинг `catalog.json`).
4)`/godot-cpp` — сабмодуль с биндингами Godot для компилирования C++ кода.

Требования

* [Godot Engine 4.x](https://godotengine.org/)
* Компилятор C++ (GCC/Clang/MSVC) и [SCons](https://scons.org/)
* [Docker](https://www.docker.com/) и Docker Compose

## Установка и запуск

### 1. Клонирование
В проекте используются сабмодули. Клонируйте репозиторий с флагом рекурсии:

```bash
git clone --recursive [https://github.com/purpeel/skilltracker.git](https://github.com/purpeel/skilltracker.git)
cd skilltracker
scons target=template_debug
```
Скомпилированная библиотека автоматически появится в директории проекта Godot.

Развертывание бэкенда
Для локального запуска сервера и базы данных используйте Docker Compose. Из корневой директории выполните:
```docker compose up -d --build```

Настройка окружения (Strava API)
Для работы синхронизации тренировок требуется настроить переменные окружения. Создайте файл .env в папке /app (или в корне, в зависимости от вашей конфигурации) и добавьте ключи приложения Strava:
```
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
```
