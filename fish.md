# Fish Configuration

Конфиг: `~/.config/fish/config.fish` | Functions: `~/.config/fish/functions/`

Fish — основной interactive shell. Bash используется для скриптов, zsh оставлен как fallback.

## Daily Commands

| Команда | Что делает |
|---------|------------|
| `dotcd` | Перейти в dotfiles repo |
| `dotstatus` | Показать `git status --short` и последние коммиты dotfiles |
| `dotdoctor` | Запустить `./doctor.sh` |
| `dotreload` | Перезагрузить fish config, а внутри tmux ещё и tmux config |
| `tmuxreload` | Перезагрузить только tmux config |
| `dotup` | Запустить `./update.sh` |
| `dotclean` | Запустить audit-only `./cleanup.sh` |

## Integrations

- `starship` prompt через `~/.config/starship/starship.toml`
- `zoxide` для быстрых переходов
- `direnv` для project-local env
- `fzf` для интерактивного поиска
- `opencode` wrapper очищает экран перед запуском

## PATH

Fish добавляет:

- `~/go/bin`
- `~/.opencode/bin`
- `~/.bun/bin`
- `~/.local/bin`

Homebrew shellenv подключается после этого, чтобы `/opt/homebrew/bin` был доступен на macOS.
