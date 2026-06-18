# Dotfiles

Мои конфигурационные файлы для macOS и Linux. Основной стек: Neovim 0.12 + Tmux + Kitty + Starship + Fish. Темы переключаются через `dotfiles theme`.

```bash
dotfiles theme list
dotfiles theme set kanagawa --apply-open
dotfiles theme set catppuccin-latte --apply-open
```

`opencode` получает generated `tui.json`, custom theme `dotfiles-*` и
синхронизированный TUI state для следующих запусков; уже открытые
opencode-сессии нужно перезапустить.

## Что включено

| Инструмент | Конфиг | Описание |
|------------|--------|----------|
| **Neovim** | `.config/nvim/` | Конфиг на Lua, vim.pack, встроенный LSP, DAP, Treesitter, snacks.nvim |
| **Tmux** | `.config/tmux/tmux.conf` | Сессии, сплиты, TPM-плагины |
| **Kitty** | `.config/kitty/` | Терминал с GPU-ускорением, Cmd-клавиши управляют tmux |
| **Alacritty** | `.config/alacritty/` | Альтернативный терминал, модульные конфиги |
| **Starship** | `.config/starship/` | Кросс-платформенный промпт, палитра управляется `dotfiles theme` |
| **Fish** | `.config/fish/` | Основной шелл, starship, zoxide, fzf, direnv |
| **Zsh** | `.zshrc` | Альтернативный шелл, zsh-syntax-highlighting |
| **Git** | `.gitconfig.template`, `.config/git/` | Delta (side-by-side diff), глобальный gitignore |
| **Bat** | `.config/bat/` | `cat` с подсветкой синтаксиса |
| **Btop** | `.config/btop/` | Системный монитор |
| **Sketchybar** | `.config/sketchybar/` | Кастомный статус-бар для macOS |
| **Skhd** | `.skhdrc` | Хоткеи для macOS |
| **Yabai** | `.yabairc` | Тайлинговый WM для macOS |
| **Pi** | `pi/agent/` | Non-secret Pi coding agent skills/extensions/settings template |

## Требования

- **macOS** или **Linux** (Ubuntu, Fedora, Arch)
- **Fish** (основной шелл)
- **Git**
- [Homebrew](https://brew.sh) (macOS) или системный пакетный менеджер (Linux)

## Установка

```bash
git clone git@github.com:iRootPro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Скрипт автоматически:
1. Установит основные пакеты (на macOS через `Brewfile`/`brew bundle`; на Linux через системный пакетный менеджер и fallback-установщики)
2. Создаст per-app симлинки в `~/.config` (`kitty`, `tmux`, `fish`, `nvim` и т.д.), не заменяя весь `~/.config`
3. Скопирует `.gitconfig.template` в `~/.gitconfig` (заполни имя и email)
4. Установит шрифт MesloLGLDZ Nerd Font
5. Установит TPM для tmux и Go-утилиты (gopls, delve)

После установки проверь окружение:

```bash
./doctor.sh
```

Основной interactive shell — `fish`: его запускают Kitty, Alacritty и tmux.
`bash` используется для скриптов, `.zshrc` оставлен как fallback.

## Структура

```
.
├── .config/
│   ├── alacritty/       # конфиг Alacritty
│   ├── bat/             # конфиг bat
│   ├── btop/            # конфиг btop
│   ├── fish/            # конфиг Fish shell
│   ├── git/             # глобальный gitignore
│   ├── kitty/           # конфиг Kitty
│   ├── nvim/            # конфиг Neovim (init.lua)
│   ├── sketchybar/      # конфиг Sketchybar (macOS)
│   ├── starship/        # конфиг Starship prompt
│   └── tmux/            # конфиг Tmux + плагины
├── config/              # декларативные каталоги dotfiles
├── docs/                # bootstrap, commit policy, стратегия dotfiles
├── scripts/             # вспомогательные скрипты
├── .zshrc               # конфиг Zsh
├── .tmux.conf           # совместимость; основной конфиг в .config/tmux/tmux.conf
├── .skhdrc              # хоткеи Skhd (macOS)
├── .yabairc             # конфиг Yabai (macOS)
├── .gitconfig.template  # шаблон git-конфига
├── Brewfile             # curated macOS packages/casks/fonts
├── doctor.sh            # проверка установки и безопасности dotfiles
├── install.sh           # установка всего
├── update.sh            # обновление пакетов и плагинов
└── cleanup.sh           # аудит кэшей и мусора
```

## Обслуживание

```bash
# Единый CLI для dotfiles
dotfiles commands
dotfiles actions
dotfiles apps
dotfiles open
dotfiles status
dotfiles doctor

# Обновить плагины Neovim/Tmux и Go dev tools
./update.sh

# Обновить системные пакеты отдельно, с подтверждением
./update.sh packages

# Проверить что можно почистить (кэши, логи, Docker, Pi sessions)
./cleanup.sh

# Проверить shell drift, symlinks, команды, scripts и secret-like tracked paths
./doctor.sh

# Посмотреть/восстановить non-secret Pi config
./scripts/pi-sync.sh status
```

`dotfiles` — единый command center поверх существующих скриптов. Он не заменяет
`install.sh`, `doctor.sh`, `update.sh` и `cleanup.sh`, а даёт стабильные команды
для shell, tmux command palette и AI-агентов:

```bash
dotfiles commands --json
dotfiles commands --markdown
dotfiles commands --check
dotfiles actions --json
dotfiles doctor --summary
dotfiles apps --missing
dotfiles open fish --print
dotfiles pi status
dotfiles debug --print
```

## Перенос на новую машину

Базовый flow:

```bash
git clone git@github.com:iRootPro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./doctor.sh
```

После этого вручную восстанови machine-local state: `~/.gitconfig`, GitHub auth,
SSH keys и секреты из password manager. Подробно: [bootstrap.md](docs/bootstrap.md).

## Правила коммитов

В git попадают только portable, non-secret настройки. Runtime state, tokens,
auth-файлы, logs, caches и machine-local credentials не коммитятся.

Перед коммитом:

```bash
git status --short
git diff
git add <related files only>
git diff --cached
git diff --cached --check
```

Подробно: [commit-policy.md](docs/commit-policy.md), [current-audit.md](docs/current-audit.md) и [dotfiles-strategy.md](docs/dotfiles-strategy.md).

## Документация

Подробные описания конфигов и хоткеев:
- [Neovim](nvim.md) — плагины, LSP, DAP, хоткеи
- [Fish](fish.md) — основной shell, aliases/functions, daily commands
- [Zsh](zsh.md) — промпт, плагины, алиасы, CLI-утилиты
- [Kitty](kitty.md) — хоткеи, настройки терминала
- [Pi](pi.md) — Pi coding agent setup, skills/extensions, restore flow
- [Command palette](docs/command-palette.md)
- [Actions catalog](docs/actions.md)
- [Apps catalog](docs/apps.md)
- [Open targets](docs/open.md)
- [New machine bootstrap](docs/bootstrap.md)
- [Commit policy](docs/commit-policy.md)
- [Current worktree audit](docs/current-audit.md)
- [Dotfiles strategy](docs/dotfiles-strategy.md)
