# Dotfiles

Мои конфигурационные файлы для macOS и Linux. Основной стек: Neovim + Tmux + Kitty + Starship + Zsh.

## Что включено

| Инструмент | Конфиг | Описание |
|------------|--------|----------|
| **Neovim** | `.config/nvim/` | Конфиг на Lua, vim.pack, LSP, DAP, Treesitter, Telescope |
| **Tmux** | `.config/tmux/`, `.tmux.conf` | Сессии, сплиты, TPM-плагины |
| **Kitty** | `.config/kitty/` | Терминал с GPU-ускорением, тема Kanagawa |
| **Alacritty** | `.config/alacritty/` | Альтернативный терминал, модульные конфиги |
| **Starship** | `.config/starship/` | Кросс-платформенный промпт, тема Kanagawa |
| **Zsh** | `.zshrc` | Oh-My-Zsh, zoxide, fzf, zsh-syntax-highlighting |
| **Git** | `.gitconfig.template`, `.config/git/` | Delta (side-by-side diff), глобальный gitignore |
| **Bat** | `.config/bat/` | `cat` с подсветкой синтаксиса |
| **Btop** | `.config/btop/` | Системный монитор |
| **Sketchybar** | `.config/sketchybar/` | Кастомный статус-бар для macOS |
| **Skhd** | `.skhdrc` | Хоткеи для macOS |
| **Yabai** | `.yabairc` | Тайлинговый WM для macOS |

## Требования

- **macOS** или **Linux** (Ubuntu, Fedora, Arch)
- **Zsh** (основной шелл)
- **Git**
- [Homebrew](https://brew.sh) (macOS) или системный пакетный менеджер (Linux)

## Установка

```bash
git clone git@github.com:iRootPro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Скрипт автоматически:
1. Установит все пакеты (neovim, tmux, starship, fzf, bat, eza, ripgrep, delta и др.)
2. Создаст симлинки (`~/.config` -> dotfiles/.config, `~/.zshrc` и т.д.)
3. Скопирует `.gitconfig.template` в `~/.gitconfig` (заполни имя и email)
4. Установит шрифт MesloLGLDZ Nerd Font
5. Установит Go-утилиты (gopls, delve)

## Структура

```
.
├── .config/
│   ├── alacritty/       # конфиг Alacritty
│   ├── bat/             # конфиг bat
│   ├── btop/            # конфиг btop
│   ├── git/             # глобальный gitignore
│   ├── kitty/           # конфиг Kitty
│   ├── nvim/            # конфиг Neovim (init.lua)
│   ├── sketchybar/      # конфиг Sketchybar (macOS)
│   ├── starship/        # конфиг Starship prompt
│   └── tmux/            # конфиг Tmux + плагины
├── scripts/             # вспомогательные скрипты
├── .zshrc               # конфиг Zsh
├── .tmux.conf           # точка входа Tmux
├── .skhdrc              # хоткеи Skhd (macOS)
├── .yabairc             # конфиг Yabai (macOS)
├── .gitconfig.template  # шаблон git-конфига
├── install.sh           # установка всего
├── update.sh            # обновление пакетов и плагинов
└── cleanup.sh           # аудит кэшей и мусора
```

## Обслуживание

```bash
# Обновить пакеты, плагины Neovim, Tmux, Zinit
./update.sh

# Проверить что можно почистить (кэши, логи, Docker)
./cleanup.sh
```

## Документация

Подробные описания конфигов и хоткеев:
- [Neovim](nvim.md) — плагины, LSP, DAP, хоткеи
- [Zsh](zsh.md) — промпт, плагины, алиасы, CLI-утилиты
- [Kitty](kitty.md) — хоткеи, настройки терминала
