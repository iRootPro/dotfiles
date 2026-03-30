#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

step() {
  echo ""
  green "── $1 ──"
}

# --- Пакетный менеджер ---
update_packages() {
  step "Пакеты"
  if [ "$OS" = "Darwin" ]; then
    brew update && brew upgrade
    brew cleanup
  elif command -v apt &>/dev/null; then
    sudo apt update -qq && sudo apt upgrade -y -qq
    sudo apt autoremove -y -qq
  elif command -v dnf &>/dev/null; then
    sudo dnf upgrade -y
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm
  fi
}

# --- Neovim плагины ---
update_nvim() {
  step "Neovim плагины"
  if command -v nvim &>/dev/null; then
    nvim --headless -c "lua vim.pack.update()" -c "qa" 2>/dev/null && green "  ✓ vim.pack" || yellow "  Пропущено"
  fi
}

# --- Zinit плагины ---
update_zinit() {
  step "Zinit плагины"
  if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit" ]; then
    zsh -ic "zinit update --all" 2>/dev/null && green "  ✓ zinit" || yellow "  Пропущено"
  fi
}

# --- Tmux плагины ---
update_tmux() {
  step "Tmux плагины"
  local tpm="$HOME/.tmux/plugins/tpm/bin/update_plugins"
  if [ -x "$tpm" ]; then
    "$tpm" all && green "  ✓ TPM"
  else
    yellow "  TPM не найден"
  fi
}

# --- Go утилиты ---
update_go() {
  step "Go утилиты"
  if command -v go &>/dev/null; then
    go install golang.org/x/tools/gopls@latest && green "  ✓ gopls"
    go install github.com/go-delve/delve/cmd/dlv@latest && green "  ✓ delve"
  else
    yellow "  Go не установлен"
  fi
}

# --- Main ---
main() {
  echo ""
  green "╔══════════════════════════════════╗"
  green "║     Dotfiles Updater             ║"
  green "║     OS: $OS                      ║"
  green "╚══════════════════════════════════╝"

  update_packages
  update_nvim
  update_zinit
  update_tmux
  update_go

  echo ""
  green "═══════════════════════════════════"
  green "  Всё обновлено!"
  green "═══════════════════════════════════"
  echo ""
}

main "$@"
