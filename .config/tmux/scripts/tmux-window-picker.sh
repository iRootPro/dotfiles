#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"

list_windows() {
  local current_window
  current_window="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"

  tmux list-windows -a -F '#{session_id}	#{window_id}	#{pane_id}	#{session_name}	#{window_index}	#{window_name}	#{window_panes}	#{?window_active,1,0}	#{pane_current_command}	#{pane_current_path}' |
    while IFS=$'\t' read -r session_id window_id pane_id session_name window_index window_name window_panes window_active pane_command pane_path; do
      local marker active_label label
      marker=" "
      active_label=""

      [ "$window_id" = "$current_window" ] && marker="●"
      [ "$window_active" = "1" ] && active_label=" active"

      label="$(printf '%s \033[34m%-18s\033[0m \033[35m#%-2s\033[0m %-22s \033[33m%-10s\033[0m \033[90m%2s panes%s\033[0m  %s' \
        "$marker" \
        "$session_name" \
        "$window_index" \
        "$window_name" \
        "$pane_command" \
        "$window_panes" \
        "$active_label" \
        "$pane_path")"

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
    list_windows | fzf-tmux -p 88%,78% \
      --ansi \
      --no-sort \
      --delimiter=$'\t' \
      --with-nth=4 \
      --border \
      --border-label=' tmux windows ' \
      --prompt=' windows  ' \
      --pointer='▶' \
      --marker='✓' \
      --info=inline-right \
      --layout=reverse \
      --header='Enter: switch  Ctrl-R: reload  Ctrl-D: close selected  Esc: cancel' \
      --preview-window='right:58%,border-left' \
      --preview='tmux display-message -p -t {2} "Session: #{session_name}  Window: #{window_index}:#{window_name}  Panes: #{window_panes}  Command: #{pane_current_command}" 2>/dev/null; printf "\n"; tmux capture-pane -ep -t {3} -S -120 2>/dev/null' \
      --bind="ctrl-r:reload($self list)" \
      --bind="ctrl-d:execute-silent($self kill {1} {2})+reload($self list)" \
      --color='bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796,fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6,marker:#a6da95,fg+:#cad3f5,prompt:#8aadf4,hl+:#ed8796,border:#6e738d,label:#c6a0f6'
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
