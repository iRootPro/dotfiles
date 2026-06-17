#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"
checks=0
failures=0
warnings=0

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }
dim() { printf "\033[2m%s\033[0m\n" "$1"; }

pass() {
  checks=$((checks + 1))
  green "  OK   $1"
}

warn() {
  checks=$((checks + 1))
  warnings=$((warnings + 1))
  yellow "  WARN $1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  red "  FAIL $1"
}

section() {
  printf '\n'
  green "-- $1 --"
}

check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd"
  else
    fail "$cmd not found"
  fi
}

check_optional_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd"
  else
    warn "$cmd not found"
  fi
}

check_link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || return 0

  if [ -e "$dst" ] && [ "$(realpath "$dst" 2>/dev/null)" = "$(realpath "$src" 2>/dev/null)" ]; then
    pass "$dst -> $src"
  elif [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    pass "$dst -> $src"
  elif [ -L "$dst" ]; then
    warn "$dst points to $(readlink "$dst"), expected $src"
  elif [ -e "$dst" ]; then
    warn "$dst exists but is not a symlink"
  else
    fail "$dst missing"
  fi
}

check_required_commands() {
  section "Commands"
  for cmd in git tmux fish nvim fzf sesh eza jq rg fd bat delta starship zoxide; do
    check_command "$cmd"
  done
  check_optional_command kitty
  check_optional_command gitmux
  check_optional_command lazygit
  check_optional_command btop
  check_optional_command opencode
}

check_primary_shell() {
  section "Primary Shell"

  local fish_path login_shell
  fish_path="$(command -v fish 2>/dev/null || true)"
  if [ -n "$fish_path" ]; then
    pass "fish at $fish_path"
  else
    fail "fish not found"
    return 0
  fi

  login_shell=""
  if [ "$OS" = "Darwin" ] && command -v dscl >/dev/null 2>&1; then
    login_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  elif command -v getent >/dev/null 2>&1; then
    login_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
  fi

  case "${login_shell##*/}" in
    fish) pass "login shell $login_shell" ;;
    "") warn "login shell unknown; expected fish" ;;
    *) warn "login shell $login_shell; expected fish" ;;
  esac
}

check_config_drift() {
  section "Config Drift"

  local old_path="Downloads/dotfiles"
  local old_refs
  old_refs="$(git -C "$ROOT" grep -nF "$old_path" -- ':!doctor.sh' 2>/dev/null || true)"
  if [ -z "$old_refs" ]; then
    pass "no tracked $old_path references"
  else
    fail "tracked $old_path references remain"
    printf '%s\n' "$old_refs"
  fi

  if [ -f "$ROOT/.config/alacritty/shared.toml" ]; then
    if grep -Eq '^[[:space:]]*program[[:space:]]*=[[:space:]]*"fish"' "$ROOT/.config/alacritty/shared.toml"; then
      pass "Alacritty shell fish"
    else
      warn "Alacritty shell is not fish"
    fi
  fi

  if [ -f "$ROOT/.config/kitty/kitty.conf" ]; then
    if grep -Eq '^[[:space:]]*shell[[:space:]]+(.*/)?fish([[:space:]]|$)' "$ROOT/.config/kitty/kitty.conf"; then
      pass "Kitty shell fish"
    else
      warn "Kitty shell is not fish"
    fi
  fi

  if [ -f "$ROOT/.config/tmux/tmux.conf" ]; then
    if grep -Eq '^[[:space:]]*set -g renumber-windows on' "$ROOT/.config/tmux/tmux.conf"; then
      pass "tmux renumber-windows on"
    else
      warn "tmux renumber-windows is not on"
    fi

    if grep -Eq 'default-shell.*fish|command -v fish' "$ROOT/.config/tmux/tmux.conf"; then
      pass "tmux config prefers fish"
    else
      warn "tmux config does not prefer fish"
    fi
  fi
}

check_symlinks() {
  section "Symlinks"

  local config_dirs=(
    agents
    alacritty
    bat
    btop
    fish
    kitty
    lofi-player
    mc
    nvim
    opencode
    sesh
    sketchybar
    starship
    tmux
  )

  for dir in "${config_dirs[@]}"; do
    check_link "$ROOT/.config/$dir" "$HOME/.config/$dir"
  done

  local config_files=(
    gh/config.yml
    git/ignore
  )

  for file in "${config_files[@]}"; do
    check_link "$ROOT/.config/$file" "$HOME/.config/$file"
  done

  check_link "$ROOT/.zshrc" "$HOME/.zshrc"
  check_link "$ROOT/.tmux.conf" "$HOME/.tmux.conf"

  if [ "$OS" = "Darwin" ]; then
    check_link "$ROOT/.skhdrc" "$HOME/.skhdrc"
    check_link "$ROOT/.yabairc" "$HOME/.yabairc"
  fi
}

check_shell_scripts() {
  section "Shell Scripts"

  local script
  while IFS= read -r script; do
    if bash -n "$script" 2>/dev/null; then
      pass "syntax ${script#$ROOT/}"
    else
      fail "syntax ${script#$ROOT/}"
    fi

    if [ -x "$script" ]; then
      pass "executable ${script#$ROOT/}"
    else
      warn "not executable ${script#$ROOT/}"
    fi
  done < <(find "$ROOT" -type f -name '*.sh' -not -path '*/.git/*' -not -path '*/plugins/*' 2>/dev/null)
}

check_fish_config() {
  section "Fish Config"
  if ! command -v fish >/dev/null 2>&1; then
    fail "fish not found"
    return 0
  fi

  local files=("$ROOT/.config/fish/config.fish")
  local fn
  while IFS= read -r fn; do
    files+=("$fn")
  done < <(find "$ROOT/.config/fish/functions" -type f -name '*.fish' 2>/dev/null)

  if fish -n "${files[@]}" 2>/dev/null; then
    pass "fish syntax"
  else
    fail "fish syntax"
  fi
}

check_brewfile() {
  [ "$OS" = "Darwin" ] || return 0
  [ -f "$ROOT/Brewfile" ] || return 0

  section "Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    fail "brew not found"
    return 0
  fi

  if brew bundle check --file="$ROOT/Brewfile" >/dev/null 2>&1; then
    pass "Brewfile satisfied"
  else
    warn "Brewfile has missing packages; run: brew bundle --file=$ROOT/Brewfile"
  fi
}

check_git_safety() {
  section "Git Safety"

  if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "$ROOT is not a git repository"
    return 0
  fi

  local tracked_secret=0
  local path
  while IFS= read -r path; do
    case "$path" in
      .env|.env.*|*.pem|*.key|*token*|*credentials*|client_secret*.json|client_secrets*.json|.config/gh/hosts.yml|.config/fish/fish_variables|pi/agent/auth.json|pi/agent/sessions/*|pi/youtube_credentials/*)
        red "  FAIL tracked secret-like path: $path"
        tracked_secret=1
        ;;
    esac
  done < <(git -C "$ROOT" ls-files)

  if [ "$tracked_secret" -eq 0 ]; then
    pass "no tracked secret-like paths"
  else
    failures=$((failures + 1))
    checks=$((checks + 1))
  fi

  if git -C "$ROOT" diff --cached --quiet; then
    pass "no staged changes"
  else
    warn "there are staged changes"
  fi
}

check_tmux_live() {
  section "Tmux"
  if ! command -v tmux >/dev/null 2>&1; then
    fail "tmux not found"
    return 0
  fi

  if tmux list-keys -T prefix U >/dev/null 2>&1; then
    pass "tmux key table readable"
  else
    warn "tmux server not running or key table unavailable"
  fi

  local default_shell default_command
  default_shell="$(tmux show-options -gv default-shell 2>/dev/null || true)"
  case "${default_shell##*/}" in
    fish) pass "tmux default-shell $default_shell" ;;
    "") warn "tmux default-shell unavailable" ;;
    *) warn "tmux default-shell $default_shell; expected fish" ;;
  esac

  default_command="$(tmux show-options -gv default-command 2>/dev/null || true)"
  if [ -z "$default_command" ] || [ "$default_command" = "exec fish" ]; then
    pass "tmux default-command ${default_command:-empty}"
  else
    warn "tmux default-command $default_command; expected empty or exec fish"
  fi

  if [ -x "$ROOT/.config/tmux/scripts/tmux-new-session.sh" ]; then
    pass "tmux-new-session.sh executable"
  else
    fail "tmux-new-session.sh is missing or not executable"
  fi
}

main() {
  printf '\n'
  green "Dotfiles doctor"
  dim "root: $ROOT"
  dim "os:   $OS"

  check_required_commands
  check_primary_shell
  check_config_drift
  check_symlinks
  check_shell_scripts
  check_fish_config
  check_brewfile
  check_git_safety
  check_tmux_live

  printf '\n'
  if [ "$failures" -gt 0 ]; then
    red "Result: $failures failures, $warnings warnings, $checks checks"
    exit 1
  fi

  if [ "$warnings" -gt 0 ]; then
    yellow "Result: $warnings warnings, $checks checks"
    exit 0
  fi

  green "Result: all $checks checks passed"
}

main "$@"
