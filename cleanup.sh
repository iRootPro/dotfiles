#!/usr/bin/env bash
set -uo pipefail

OS="$(uname -s)"

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }
dim() { printf "\033[2m%s\033[0m\n" "$1"; }
bold() { printf "\033[1m%s\033[0m\n" "$1"; }

human_size() {
  local bytes=$1
  if [ "$bytes" -gt 1073741824 ]; then
    echo "$(( bytes / 1073741824 ))G"
  elif [ "$bytes" -gt 1048576 ]; then
    echo "$(( bytes / 1048576 ))M"
  elif [ "$bytes" -gt 1024 ]; then
    echo "$(( bytes / 1024 ))K"
  else
    echo "${bytes}B"
  fi
}

dir_size() {
  if [ -d "$1" ]; then
    du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
  else
    echo 0
  fi
}

TOTAL_RECLAIMABLE=0
ITEMS=()

suggest() {
  local size=$1 desc="$2" cmd="$3"
  if [ "$size" -gt 0 ]; then
    TOTAL_RECLAIMABLE=$(( TOTAL_RECLAIMABLE + size ))
    ITEMS+=("$(printf "  %-8s %s\n         → %s" "$(human_size "$size")" "$desc" "$cmd")")
  fi
}

# ─── Кэши ───

check_caches() {
  bold "Кэши"
  echo ""

  # Homebrew cache
  if command -v brew &>/dev/null; then
    local brew_cache
    brew_cache=$(dir_size "$(brew --cache 2>/dev/null)")
    suggest "$brew_cache" "Homebrew кэш (старые бутылки)" "brew cleanup --prune=all"
  fi

  # Go module cache
  if command -v go &>/dev/null; then
    local go_cache
    go_cache=$(dir_size "$(go env GOMODCACHE 2>/dev/null)")
    local go_build
    go_build=$(dir_size "$(go env GOCACHE 2>/dev/null)")
    suggest "$go_cache" "Go module cache" "go clean -modcache"
    suggest "$go_build" "Go build cache" "go clean -cache"
  fi

  # npm cache
  if [ -d "$HOME/.npm" ]; then
    local npm_cache
    npm_cache=$(dir_size "$HOME/.npm")
    suggest "$npm_cache" "npm кэш" "npm cache clean --force"
  fi

  # pip cache
  local pip_dir="$HOME/.cache/pip"
  [ "$OS" = "Darwin" ] && pip_dir="$HOME/Library/Caches/pip"
  if [ -d "$pip_dir" ]; then
    local pip_cache
    pip_cache=$(dir_size "$pip_dir")
    suggest "$pip_cache" "pip кэш" "pip cache purge"
  fi

  # Neovim caches
  local nvim_cache="$HOME/.cache/nvim"
  if [ -d "$nvim_cache" ]; then
    local nv_cache
    nv_cache=$(dir_size "$nvim_cache")
    suggest "$nv_cache" "Neovim кэш (swap, undo, shada)" "rm -rf ~/.cache/nvim"
  fi

  # macOS caches (быстрая оценка без глубокого сканирования)
  if [ "$OS" = "Darwin" ] && [ -d "$HOME/Library/Caches" ]; then
    local mac_count
    mac_count=$(ls -1 "$HOME/Library/Caches" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$mac_count" -gt 0 ]; then
      dim "  ~/Library/Caches: $mac_count приложений (du слишком долгий)"
      dim "  → Смотри вручную: du -sh ~/Library/Caches/* | sort -rh | head -10"
      echo ""
    fi
  fi
}

# ─── Docker ───

check_docker() {
  if ! command -v docker &>/dev/null; then return; fi
  if ! docker info &>/dev/null 2>&1; then return; fi

  bold "Docker"
  echo ""

  local dangling
  dangling=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dangling" -gt 0 ]; then
    suggest 0 "$dangling dangling образов" "docker image prune -f"
  fi

  local volumes
  volumes=$(docker volume ls -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
  if [ "$volumes" -gt 0 ]; then
    suggest 0 "$volumes неиспользуемых volumes" "docker volume prune -f"
  fi

  local docker_usage
  docker_usage=$(docker system df --format '{{.Reclaimable}}' 2>/dev/null | head -1)
  if [ -n "$docker_usage" ]; then
    dim "  Docker reclaimable: $docker_usage"
    dim "  → docker system prune -a"
    echo ""
  fi
}

# ─── Brew ───

check_brew_orphans() {
  if ! command -v brew &>/dev/null; then return; fi

  bold "Brew: пакеты-сироты"
  echo ""

  local output
  output=$(brew autoremove --dry-run 2>&1) || true
  local orphans
  orphans=$(echo "$output" | grep -c "Would uninstall" || true)
  if [ "$orphans" -gt 0 ]; then
    suggest 0 "$orphans brew пакетов без зависимостей" "brew autoremove"
    echo "$output" | grep "Would uninstall" | while read -r line; do
      dim "    $line"
    done
    echo ""
  else
    green "  Сирот нет"
    echo ""
  fi
}

# ─── Brew: неиспользуемые пакеты ───

check_brew_unused() {
  if ! command -v brew &>/dev/null; then return; fi

  bold "Brew: пакеты вне основного набора"
  dim "  (установлены вручную, не входят в dotfiles/install.sh)"
  echo ""

  # Список пакетов которые точно нужны (из install.sh + рабочие инструменты)
  local keep="neovim|tmux|starship|zoxide|fzf|bat|eza|fd|ripgrep|git-delta|direnv|lazygit|btop|jq|go|gopls|lua-language-server|yaml-language-server|tree-sitter|docker|nvm|pass|wget|yq|pipx|uv|rust|pnpm|openjdk@17|ffmpeg|imagemagick|nmap|telnet"

  local extra=()
  while IFS= read -r pkg; do
    echo "$pkg" | grep -qE "^($keep)$" && continue
    extra+=("$pkg")
    dim "    $pkg"
  done < <(brew leaves --installed-on-request 2>/dev/null)

  if [ ${#extra[@]} -gt 0 ]; then
    echo ""
    yellow "  ${#extra[@]} пакетов не в основном наборе. Нужны?"
    yellow "  → brew uninstall ${extra[*]}"
    echo ""
  else
    green "  Только нужные пакеты"
    echo ""
  fi
}

# ─── Большие файлы в домашней директории ───

check_large_dirs() {
  bold "Большие директории (dev-related)"
  echo ""

  local check_dirs=(
    "$HOME/.cache" "$HOME/.local" "$HOME/.npm" "$HOME/.bun"
    "$HOME/.cargo" "$HOME/.rustup" "$HOME/.gvm"
    "$HOME/go" "$HOME/node_modules"
    "$HOME/.docker" "$HOME/.gradle" "$HOME/.m2"
    "$HOME/.local/share/zinit"
    "$HOME/.tmux"
  )

  for d in "${check_dirs[@]}"; do
    if [ -d "$d" ]; then
      local size
      size=$(du -sk "$d" 2>/dev/null | awk '{print $1}')
      local name="${d/#$HOME/~}"
      if [ "${size:-0}" -gt 1048576 ]; then  # > 1G
        red "  $(printf "%-8s %s" "$(human_size $((size * 1024)))" "$name")"
      elif [ "${size:-0}" -gt 102400 ]; then  # > 100M
        yellow "  $(printf "%-8s %s" "$(human_size $((size * 1024)))" "$name")"
      fi
    fi
  done
  echo ""
}

# ─── Старые логи ───

check_logs() {
  bold "Логи"
  echo ""

  if [ "$OS" = "Darwin" ] && [ -d "$HOME/Library/Logs" ]; then
    local logs_size
    logs_size=$(dir_size "$HOME/Library/Logs")
    suggest "$logs_size" "~/Library/Logs" "rm -rf ~/Library/Logs/*"
  fi

  if [ -d "$HOME/.local/state" ]; then
    local state_size
    state_size=$(dir_size "$HOME/.local/state")
    if [ "$state_size" -gt 10485760 ]; then  # > 10M
      suggest "$state_size" "~/.local/state" "# Удалять выборочно: du -sh ~/.local/state/*"
    fi
  fi
}

# ─── Старые загрузки ───

check_downloads() {
  bold "Старые файлы в ~/Downloads (>30 дней)"
  echo ""

  local count=0
  local total_size=0
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      count=$((count + 1))
      local fsize
      fsize=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
      total_size=$((total_size + fsize))
    fi
  done < <(find "$HOME/Downloads" -maxdepth 1 -type f -mtime +30 2>/dev/null)

  if [ "$count" -gt 0 ]; then
    suggest "$total_size" "$count файлов старше 30 дней в ~/Downloads" "# Проверь: find ~/Downloads -maxdepth 1 -type f -mtime +30"
  else
    green "  Чисто"
  fi
  echo ""
}

# ─── Main ───

main() {
  echo ""
  green "╔══════════════════════════════════╗"
  green "║     Dotfiles Cleanup Audit       ║"
  green "║     OS: $OS                      ║"
  green "╚══════════════════════════════════╝"
  echo ""

  check_caches
  check_docker
  check_brew_orphans
  check_brew_unused
  check_large_dirs
  check_logs
  check_downloads

  echo ""
  bold "═══ Рекомендации ═══"
  echo ""

  if [ ${#ITEMS[@]} -eq 0 ]; then
    green "  Всё чисто, нечего удалять!"
  else
    for item in "${ITEMS[@]}"; do
      echo "$item"
      echo ""
    done
    echo ""
    bold "  Можно освободить ~$(human_size $TOTAL_RECLAIMABLE)"
    echo ""
    yellow "  Скрипт ничего не удаляет — только показывает команды."
    yellow "  Скопируй нужную и выполни вручную."
  fi
  echo ""
}

main "$@"
