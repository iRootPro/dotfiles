#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"
FAILED_STEPS=()

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

step() {
  echo ""
  green "── $1 ──"
}

usage() {
  cat <<'EOF'
Usage: ./update.sh [plugins|packages|nvim|tmux|go|all]

Default: plugins

Modes:
  plugins   Update Neovim, Tmux plugins and Go dev tools
  packages  Update system packages only, with confirmation
  all       Run packages + plugins
EOF
}

run_update() {
  local name="$1"
  shift

  if "$@"; then
    return 0
  fi

  FAILED_STEPS+=("$name")
  red "  ✗ $name failed; continuing"
  return 0
}

confirm_packages() {
  local answer=""

  if [ "${DOTFILES_ASSUME_YES:-}" = "1" ]; then
    return 0
  fi

  yellow "System package updates may upgrade many packages. Continue? [y/N]"
  if [ -r /dev/tty ]; then
    IFS= read -r answer </dev/tty
  else
    yellow "  Пропущено (нет интерактивного TTY; set DOTFILES_ASSUME_YES=1 to run)"
    return 1
  fi

  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) yellow "  Пропущено"; return 1 ;;
  esac
}

# --- Пакетный менеджер ---
update_packages() {
  step "Пакеты"
  confirm_packages || return 0

  if [ "$OS" = "Darwin" ]; then
    brew update && brew upgrade
  elif command -v apt &>/dev/null; then
    sudo apt update -qq && sudo apt upgrade -y -qq
  elif command -v dnf &>/dev/null; then
    sudo dnf upgrade -y
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu
  fi
}

# --- Neovim плагины ---
update_nvim() {
  step "Neovim плагины"
  if command -v nvim &>/dev/null; then
    nvim --headless -c "lua vim.pack.update()" -c "qa" 2>/dev/null && green "  ✓ vim.pack" || {
      red "  ✗ vim.pack"
      return 1
    }
  else
    yellow "  Neovim не установлен"
  fi
}

# --- Tmux плагины ---
update_tmux() {
  step "Tmux плагины"
  local tpm="$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
  if [ -x "$tpm" ]; then
    "$tpm" all && green "  ✓ TPM" || {
      red "  ✗ TPM"
      return 1
    }
  else
    yellow "  TPM не найден"
  fi
}

update_plugins() {
  run_update "Neovim plugins" update_nvim
  run_update "Tmux plugins" update_tmux
  run_update "Go tools" update_go
}

# --- Go утилиты ---
update_go() {
  local failed=0

  step "Go утилиты"
  if command -v go &>/dev/null; then
    go install golang.org/x/tools/gopls@latest && green "  ✓ gopls" || {
      red "  ✗ gopls"
      failed=1
    }
    go install github.com/go-delve/delve/cmd/dlv@latest && green "  ✓ delve" || {
      red "  ✗ delve"
      failed=1
    }
    if [ "$OS" != "Darwin" ]; then
      go install github.com/joshmedeski/sesh/v2@latest && green "  ✓ sesh" || {
        red "  ✗ sesh"
        failed=1
      }
    fi
  else
    yellow "  Go не установлен"
  fi

  return "$failed"
}

# --- Main ---
main() {
  local mode="${1:-plugins}"

  echo ""
  green "╔══════════════════════════════════╗"
  green "║     Dotfiles Updater             ║"
  green "║     OS: $OS                      ║"
  green "╚══════════════════════════════════╝"

  case "$mode" in
    packages) run_update "System packages" update_packages ;;
    plugins) update_plugins ;;
    nvim) run_update "Neovim plugins" update_nvim ;;
    tmux) run_update "Tmux plugins" update_tmux ;;
    go) run_update "Go tools" update_go ;;
    all)
      run_update "System packages" update_packages
      update_plugins
      ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac

  echo ""
  if [ "${#FAILED_STEPS[@]}" -gt 0 ]; then
    red "═══════════════════════════════════"
    red "  Обновление завершено с ошибками:"
    printf '  - %s\n' "${FAILED_STEPS[@]}"
    red "═══════════════════════════════════"
    exit 1
  fi

  green "═══════════════════════════════════"
  green "  Всё обновлено!"
  green "═══════════════════════════════════"
  echo ""
}

main "$@"
