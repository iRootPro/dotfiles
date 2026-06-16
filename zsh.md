# Zsh Configuration

Конфиг: `~/.zshrc` | Промпт: `~/.config/starship/starship.toml`

## Структура

```
~/.zprofile          # brew shellenv (загружается при логине)
~/.zshrc             # основной конфиг (загружается при каждом терминале)
~/.config/starship/  # настройки промпта (тема Catppuccin Mocha)
```

## Плагины

Zsh-конфиг не использует отдельный plugin manager. Если пакеты установлены через Homebrew или системный пакетный менеджер, `.zshrc` подхватывает их напрямую.

| Плагин | Что делает |
|--------|-----------|
| zsh-autosuggestions | Серые подсказки из истории (→ принять, Alt+→ принять слово) |
| zsh-syntax-highlighting | Подсветка команд: зелёный = валидная, красный = ошибка |
| carapace | Дополнительные автодополнения, если установлен |

## Навигация

| Команда | Что делает |
|---------|-----------|
| `z <dir>` | Перейти в часто используемую директорию (zoxide, умный cd) |
| `zi` | Интерактивный выбор директории через fzf |

Zoxide учится на твоих `cd` — чем чаще заходишь в папку, тем выше приоритет.

## Поиск: FZF

| Хоткей | Что делает |
|--------|-----------|
| `Ctrl+R` | Поиск по истории команд |
| `fzf` | Доступен как CLI, если установлен |

## Сессии: Sesh + Tmux

| Команда | Что делает |
|---------|-----------|
| `t` | `sesh connect` — быстрое подключение к сессии |
| `Cmd+O` в Kitty | Fuzzy-выбор tmux/sesh-сессии через tmux popup |

## CLI-утилиты

| Алиас | Команда | Что это |
|-------|---------|---------|
| `cat` | `bat` | Просмотр файлов с подсветкой синтаксиса, номерами строк, git diff |
| `ls` | `eza --icons` | Список файлов с иконками |
| `ll` | `eza --icons -la` | Подробный список (все файлы) |
| `lt` | `eza --icons --tree --level=2` | Дерево файлов (2 уровня) |
| `fd` | `fd` | Быстрый поиск файлов (замена find). Примеры: `fd .go`, `fd -e yaml` |

Конфиг bat: `~/.config/bat/config`

### delta (git pager)

Все `git diff`, `git show`, `git log -p` отображаются с подсветкой синтаксиса в режиме side-by-side. Навигация: `n`/`N` — следующий/предыдущий файл.

Конфиг: `~/.gitconfig` (секции `[core]`, `[delta]`)

### direnv

Автоматические переменные окружения при входе в директорию. Создай `.envrc` в проекте:

```bash
# ~/projects/my-api/.envrc
export DATABASE_URL="postgres://localhost:5432/mydb"
export API_KEY="dev-key-123"
```

При входе в директорию: `direnv allow` (один раз), дальше переменные загружаются/выгружаются автоматически.

## Редакторы

| Алиас | Команда | Что это |
|-------|---------|---------|
| `nv` | `nvim` | Neovim |

## Версии и рантаймы

| Инструмент | Назначение | Проверка |
|------------|-----------|----------|
| GVM | Go Version Manager | `gvm list` / `gvm use go1.22` |
| Bun | JS/TS рантайм и пакетный менеджер | `bun --version` |

## Автодополнения

Работают из коробки (Tab):
- **git** — ветки, команды, remotes
- **pass** — записи из password store
- **bun** — команды и скрипты
- Сотни других CLI через zsh-completions

## PATH

Порядок приоритета (первый найденный бинарник побеждает):

1. `~/.opencode/bin`
2. `~/.bun/bin`
3. `~/.local/bin` (pipx, пользовательские скрипты)
4. `/opt/homebrew/bin` или `/usr/local/bin` через `brew shellenv`, если Homebrew установлен
5. `/usr/local/go/bin`, `~/go/bin`
6. Системные `/usr/bin`, `/bin`

## Промпт: Starship

Конфиг: `~/.config/starship/starship.toml`, тема `Catppuccin Mocha`.

Показывает:
- Текущую директорию
- Git-ветку и статус (staged/modified/deleted/stashed/untracked/conflicted)
- Версии языков (Go, Node, Rust, Python, C, Java, Kotlin, PHP, Haskell) — только в проектах
- Docker-контекст, Terraform
- Иконки для GitHub/GitLab/Bitbucket
- Индикатор git worktree
- Время выполнения долгих команд (>3 сек)

## Обслуживание

```bash
# Обновить dotfiles-плагины и Go tools
dotup

# Пересобрать кэш автодополнений (если что-то не дополняется)
rm -f ~/.zcompdump && compinit

# Откатиться на старый конфиг
cp ~/.zshrc.bak ~/.zshrc
```
