#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-open}"
status_script="${TMUX_PI_STATUS_SCRIPT:-$HOME/.config/tmux/scripts/tmux-pi-status.sh}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'
[ -f "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors" ] && fzf_colors="$(cat "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors")"

[ -x "$status_script" ] || {
  printf 'Pi status script not found: %s\nPress Enter...' "$status_script"
  IFS= read -r _ || true
  exit 1
}

color_for_status() {
  case "$1" in
    error) printf '\033[31;1m' ;;
    attention) printf '\033[33;1m' ;;
    working) printf '\033[36m' ;;
    done) printf '\033[32m' ;;
    dead) printf '\033[31m' ;;
    idle|*) printf '\033[90m' ;;
  esac
}

label_for_status() {
  case "$1" in
    attention) printf 'needs input' ;;
    *) printf '%s' "$1" ;;
  esac
}

shorten() {
  local value="$1" max="${2:-34}"
  if [[ "$value" == "$HOME"* ]]; then
    value="~${value#$HOME}"
  fi
  if [ "${#value}" -gt "$max" ]; then
    printf '…%s' "${value: -$((max - 1))}"
  else
    printf '%s' "$value"
  fi
}

rows() {
  local reset=$'\033[0m' bold=$'\033[1m' dim=$'\033[90m'
  local data
  data="$($status_script list)"
  [ -n "$data" ] || return 0

  printf '%s\n' "$data" | sort -t $'\t' -k9,9n -k2,2 -k4,4n | \
    while IFS=$'\t' read -r session_id session_name window_id window_index window_name pane_id status icon priority pane_path pane_cmd pane_title summary; do
      local color label location path_short display
      color="$(color_for_status "$status")"
      label="$(label_for_status "$status")"
      location="${session_name} › ${window_index}:${window_name}"
      path_short="$(shorten "$pane_path" 32)"
      [ -n "$summary" ] || summary="waiting for prompt"

      display="$(printf '%b%-17s%b  %b%-26s%b  %-8s  %b%-32s%b  %s' \
        "$color" "$icon $label" "$reset" \
        "$bold" "$location" "$reset" \
        "$pane_id" \
        "$dim" "$path_short" "$reset" \
        "$summary")"

      printf '%s\t%s\t%s\t%s\t%s\n' "$priority" "$session_id" "$window_id" "$pane_id" "$display"
    done
}

preview() {
  local pane_id="${1:-}"
  [ -n "$pane_id" ] || exit 0

  local line
  line="$($status_script list | awk -F '\t' -v pane="$pane_id" '$6 == pane { print; exit }')"
  if [ -z "$line" ]; then
    printf 'Pane not found: %s\n' "$pane_id"
    exit 0
  fi

  local session_id session_name window_id window_index window_name status icon priority pane_path pane_cmd pane_title summary
  IFS=$'\t' read -r session_id session_name window_id window_index window_name _pane status icon priority pane_path pane_cmd pane_title summary <<<"$line"

  local color reset bold dim label path_short
  color="$(color_for_status "$status")"
  reset=$'\033[0m'
  bold=$'\033[1m'
  dim=$'\033[90m'
  label="$(label_for_status "$status")"
  path_short="$(shorten "$pane_path" 80)"
  [ -n "$summary" ] || summary="waiting for prompt"

  printf '%b%s%b\n' "$bold" 'Pi agent' "$reset"
  printf '%b────────────────────────────────────────────────────────%b\n' "$dim" "$reset"
  printf 'Status:   %b%s %s%b\n' "$color" "$icon" "$label" "$reset"
  printf 'Location: %s › %s:%s › %s\n' "$session_name" "$window_index" "$window_name" "$pane_id"
  printf 'Command:  %s\n' "$pane_cmd"
  printf 'Path:     %s\n' "$path_short"
  [ -n "$pane_title" ] && printf 'Title:    %s\n' "$pane_title"
  printf 'Summary:  %s\n' "$summary"
  printf '\n%bRecent output%b\n' "$bold" "$reset"
  printf '%b────────────────────────────────────────────────────────%b\n' "$dim" "$reset"

  tmux capture-pane -p -t "$pane_id" -S -45 2>/dev/null | awk '
    BEGIN { blank = 0 }
    {
      gsub(/\r/, "")
      if ($0 ~ /^[[:space:]]*$/) {
        blank++
        if (blank > 1) next
      } else {
        blank = 0
      }
      print
    }' | tail -35
}

kill_pane() {
  local pane_id="${1:-}"
  [ -n "$pane_id" ] || exit 0
  tmux kill-pane -t "$pane_id" 2>/dev/null || true
}

open_dashboard() {
  local row_count
  row_count="$(rows | wc -l | tr -d ' ')"
  if [ "${row_count:-0}" -eq 0 ]; then
    printf 'No Pi agents found.\nPress Enter...'
    IFS= read -r _ || true
    exit 0
  fi

  local selected
  selected="$(rows | FZF_DEFAULT_OPTS= fzf \
    --ansi \
    --delimiter=$'\t' \
    --with-nth=5 \
    --prompt='pi agents> ' \
    --header=$'STATUS             LOCATION                    PANE      PATH                              SUMMARY\nEnter: jump  •  Ctrl-R: refresh  •  Ctrl-X: kill pane  •  Esc: close' \
    --border \
    --border-label=' Pi agents across tmux sessions ' \
    --reverse \
    --height=100% \
    --info=inline-right \
    --color="$fzf_colors" \
    --preview-window='right:62%,border-left,wrap' \
    --preview="$self preview {4}" \
    --bind="ctrl-r:reload($self rows)" \
    --bind="ctrl-x:execute-silent($self kill {4})+reload($self rows)")" || exit 0

  [ -n "$selected" ] || exit 0

  local session_id window_id pane_id
  session_id="$(printf '%s' "$selected" | awk -F '\t' '{print $2}')"
  window_id="$(printf '%s' "$selected" | awk -F '\t' '{print $3}')"
  pane_id="$(printf '%s' "$selected" | awk -F '\t' '{print $4}')"

  tmux switch-client -t "$session_id"
  tmux select-window -t "$window_id"
  tmux select-pane -t "$pane_id"
}

case "$mode" in
  rows) rows ;;
  preview) preview "${2:-}" ;;
  kill) kill_pane "${2:-}" ;;
  open|*) open_dashboard ;;
esac
