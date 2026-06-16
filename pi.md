# Pi coding agent setup

Личный reproducible слой для [pi.dev](https://pi.dev). В репозитории хранится только non-secret часть конфигурации.

## Что хранится

- `pi/agent/settings.template.json` — шаблон `~/.pi/agent/settings.json` с проверенными пакетами.
- `pi/agent/extensions/` — локальные расширения Pi.
- `pi/agent/skills/` — личные skills без секретов.
- `scripts/pi-sync.sh` — backup/restore non-secret Pi config.

## Что не хранить в git

- `~/.pi/agent/auth.json`
- `~/.pi/agent/sessions/`
- `~/.pi/youtube_credentials/`
- OAuth/API tokens, cookies, provider keys
- временные subagent artifacts и exported sessions с чувствительным контекстом

## Установка / восстановление

```bash
# Из корня dotfiles
./scripts/pi-sync.sh restore
```

Скрипт:

1. создаёт `~/.pi/agent/extensions` и `~/.pi/agent/skills`;
2. копирует туда tracked extensions/skills;
3. если `~/.pi/agent/settings.json` отсутствует — создаёт его из template;
4. не трогает auth, sessions и credentials.

После восстановления:

```bash
pi list
pi --version
```

## Backup текущей non-secret конфигурации

```bash
./scripts/pi-sync.sh backup
```

Копирует из `~/.pi/agent/extensions` и `~/.pi/agent/skills` в `pi/agent/`. Секреты и sessions не копируются.

## Обновления

Проверить последнюю версию:

```bash
pi --version
python3 - <<'PY'
import urllib.request
print(urllib.request.urlopen('https://pi.dev/api/latest-version', timeout=10).read().decode())
PY
```

Обновить Pi и пакеты вручную:

```bash
pi update --self
pi update --extensions
pi list
```

В `settings.template.json` пакеты закреплены версиями для воспроизводимости. Если сознательно хочешь rolling updates — убери `@version` у package specs.

## Текущий рекомендуемый workflow

- Обычный режим: YOLO, быстрое выполнение.
- Для безопасного планирования: `/plan <task>` из `@devkade/pi-plan`.
- Для визуального review/approval: `/plannotator` или `/plannotator-review`.
- Для сложной разработки: parent orchestration + `pi-subagents`:
  - один writer (`worker`),
  - parallel read-only reviewers/researchers,
  - fresh reviewers для diff review,
  - forked `oracle` когда нужен аудит решений и drift.

## Локальные команды

- `/gitinfo` — toggle/refresh Git status widget.
- `/plannotator` — plan review UI.
- `/plannotator-review` — browser code review UI.
- `/plan` — read-only plan mode с approval handoff.
- `/frontend-design` — frontend design prompt/skill.

## Safety заметки

- Pi packages/extensions имеют полный доступ к системе: ставить только trusted packages.
- Перед public video upload проверять metadata и privacy; default upload должен быть осознанным.
- `habit-monthly-report` ходит в production DB — подтверждать такие запросы явно.
- Периодически запускать `./cleanup.sh`: он показывает размер `~/.pi/agent/sessions`, но ничего не удаляет.
