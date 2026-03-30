#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

# --- Цвета ---
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

# --- Симлинк с бэкапом ---
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    yellow "  Бэкап: $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -s "$src" "$dst"
  green "  ✓ $dst → $src"
}

# --- Установка пакетов ---
install_packages() {
  local packages=(
    neovim tmux starship zoxide fzf
    bat eza fd ripgrep git-delta direnv
    lazygit btop jq
  )

  if [ "$OS" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
      yellow "Установка Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    green "Установка пакетов через brew..."
    brew install "${packages[@]}" 2>/dev/null || true

  elif [ "$OS" = "Linux" ]; then
    if command -v apt &>/dev/null; then
      green "Установка пакетов через apt..."
      sudo apt update -qq
      sudo apt install -y -qq neovim tmux fzf ripgrep fd-find bat jq direnv 2>/dev/null || true
      # Пакеты которых нет в apt — через cargo/go/binary
      install_from_binary
    elif command -v dnf &>/dev/null; then
      green "Установка пакетов через dnf..."
      sudo dnf install -y neovim tmux fzf ripgrep fd-find bat jq direnv 2>/dev/null || true
      install_from_binary
    elif command -v pacman &>/dev/null; then
      green "Установка пакетов через pacman..."
      sudo pacman -S --noconfirm neovim tmux fzf ripgrep fd bat eza git-delta starship zoxide jq direnv lazygit btop 2>/dev/null || true
    else
      red "Неизвестный пакетный менеджер. Установи пакеты вручную."
      return 1
    fi
  fi
}

install_from_binary() {
  # starship
  if ! command -v starship &>/dev/null; then
    yellow "Установка starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  # zoxide
  if ! command -v zoxide &>/dev/null; then
    yellow "Установка zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi
  # eza
  if ! command -v eza &>/dev/null; then
    yellow "Установка eza..."
    cargo install eza 2>/dev/null || yellow "  Пропущено (нужен cargo)"
  fi
  # delta
  if ! command -v delta &>/dev/null; then
    yellow "Установка delta..."
    cargo install git-delta 2>/dev/null || yellow "  Пропущено (нужен cargo)"
  fi
  # lazygit
  if ! command -v lazygit &>/dev/null; then
    yellow "Установка lazygit..."
    go install github.com/jesseduffield/lazygit@latest 2>/dev/null || yellow "  Пропущено (нужен go)"
  fi
  # btop
  if ! command -v btop &>/dev/null; then
    sudo apt install -y btop 2>/dev/null || sudo dnf install -y btop 2>/dev/null || yellow "  btop: установи вручную"
  fi
  # bat на Ubuntu называется batcat
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    green "  ✓ batcat → bat"
  fi
  # fd на Ubuntu называется fdfind
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    green "  ✓ fdfind → fd"
  fi
}

# --- Линковка конфигов ---
link_configs() {
  green "Линковка конфигов..."

  # ~/.config → dotfiles/.config
  link "$DOTFILES/.config" "$HOME/.config"

  # Файлы в домашней директории
  link "$DOTFILES/.zshrc" "$HOME/.zshrc"
  link "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"

  # gitconfig из шаблона (не перезаписывает существующий)
  if [ ! -f "$HOME/.gitconfig" ]; then
    cp "$DOTFILES/.gitconfig.template" "$HOME/.gitconfig"
    yellow "  Скопирован .gitconfig.template → ~/.gitconfig — заполни имя и email!"
  else
    green "  ✓ ~/.gitconfig уже существует (пропущено)"
  fi

  # macOS-only
  if [ "$OS" = "Darwin" ]; then
    link "$DOTFILES/.skhdrc" "$HOME/.skhdrc"
    link "$DOTFILES/.yabairc" "$HOME/.yabairc"
  fi
}

# --- Установка шрифтов ---
install_fonts() {
  if fc-list 2>/dev/null | grep -qi "meslo" || [ -f "$HOME/Library/Fonts/MesloLGLDZNerdFontMono-Regular.ttf" ]; then
    green "Nerd Font уже установлен"
    return
  fi

  yellow "Установка MesloLGLDZ Nerd Font..."
  local font_dir
  if [ "$OS" = "Darwin" ]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
  fi

  local tmp
  tmp=$(mktemp -d)
  curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz" -o "$tmp/Meslo.tar.xz"
  tar -xf "$tmp/Meslo.tar.xz" -C "$font_dir"
  rm -rf "$tmp"

  if [ "$OS" = "Linux" ]; then
    fc-cache -fv >/dev/null 2>&1
  fi
  green "  ✓ Nerd Font установлен"
}

# --- Go tools ---
install_go_tools() {
  if ! command -v go &>/dev/null; then
    yellow "Go не установлен — пропускаю Go-утилиты"
    return
  fi

  green "Установка Go-утилит..."
  go install github.com/go-delve/delve/cmd/dlv@latest
  go install golang.org/x/tools/gopls@latest
  green "  ✓ delve, gopls"
}

# --- Main ---
main() {
  echo ""
  green "╔══════════════════════════════════╗"
  green "║     Dotfiles Installer           ║"
  green "║     OS: $OS                      ║"
  green "╚══════════════════════════════════╝"
  echo ""

  install_packages
  echo ""
  link_configs
  echo ""
  install_fonts
  echo ""
  install_go_tools
  echo ""

  green "═══════════════════════════════════"
  green "  Готово! Перезапусти терминал."
  green "═══════════════════════════════════"
  echo ""
  yellow "  Следующие шаги:"
  echo "  1. Открой новый терминал"
  echo "  2. Запусти nv — плагины установятся автоматически"
  echo "  3. Проверь: starship, zoxide, fzf, bat, eza"
  echo ""
}

main "$@"
