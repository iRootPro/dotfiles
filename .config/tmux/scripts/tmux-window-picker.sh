#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'

list_windows() {
  local current_window
  current_window="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"

  tmux list-windows -a -F '#{session_id}	#{window_id}	#{pane_id}	#{session_name}	#{window_index}	#{window_name}	#{window_panes}	#{?window_active,1,0}	#{pane_current_command}	#{pane_current_path}' |
    while IFS=$'\t' read -r session_id window_id pane_id session_name window_index window_name window_panes window_active pane_command pane_path; do
      local marker active_label label display_path
      marker=" "
      active_label=""

      [ "$window_id" = "$current_window" ] && marker="●"
      [ "$window_active" = "1" ] && active_label=" active"
      display_path="$pane_path"
      if [[ "$display_path" == "$HOME"* ]]; then
        display_path="~${display_path#$HOME}"
      fi

      label="$(printf '%s \033[35m#%-2s\033[0m %-18s \033[33m%-10s\033[0m \033[90m%s%s\033[0m' \
        "$marker" \
        "$window_index" \
        "$window_name" \
        "$pane_command" \
        "$display_path" \
        "$active_label")"

      printf "'%s'\t%s\t%s\t%b\n" "$session_id" "$window_id" "$pane_id" "$label"
    done
}

kill_window() {
  local session_id="${1:-}" window_id="${2:-}"
  [ -n "$session_id" ] && [ -n "$window_id" ] || exit 0

  local windows current_session replacement
  windows="$(tmux display-message -p -t "$session_id" '#{session_windows}' 2>/dev/null || printf '0')"
  current_session="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"

  if [ "$windows" -gt 1 ]; then
    tmux unlink-window -k -t "$window_id" 2>/dev/null || true
    exit 0
  fi

  if [ "$session_id" = "$current_session" ]; then
    replacement="$(tmux list-sessions -F '#{session_id}' | grep -vxF "$session_id" | head -n 1 || true)"
    [ -n "$replacement" ] && tmux switch-client -t "$replacement"
  fi

  tmux kill-session -t "$session_id" 2>/dev/null || true
}

pick_window() {
  local selected session_id window_id

  selected="$(
    list_windows | fzf-tmux -p 64%,42% \
      --ansi \
      --no-sort \
      --delimiter=$'\t' \
      --with-nth=4 \
      --border \
      --border-label=' tmux · windows ' \
      --prompt='window › ' \
      --pointer='▶' \
      --marker='✓' \
      --info=inline-right \
      --layout=reverse \
      --header='enter switch · c-r reload · c-d close · esc cancel' \
      --bind="ctrl-r:reload($self list)" \
      --bind="ctrl-d:execute-silent($self kill {1} {2})+reload($self list)" \
      --color="$fzf_colors"
  )" || exit 0

  [ -n "$selected" ] || exit 0

  session_id="${selected%%$'\t'*}"
  session_id="${session_id#\'}"
  session_id="${session_id%\'}"
  selected="${selected#*$'\t'}"
  window_id="${selected%%$'\t'*}"

  tmux switch-client -t "$session_id"
  tmux select-window -t "$window_id"
}

case "$mode" in
  list) list_windows ;;
  kill) kill_window "${2:-}" "${3:-}" ;;
  pick|*) pick_window ;;
esac
