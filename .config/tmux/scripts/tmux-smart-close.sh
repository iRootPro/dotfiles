#!/usr/bin/env bash
set -euo pipefail

current_session="$(tmux display-message -p '#{session_id}')"
window_panes="$(tmux display-message -p '#{window_panes}')"
session_windows="$(tmux display-message -p '#{session_windows}')"

if [ "$window_panes" -gt 1 ]; then
  exec tmux kill-pane
fi

if [ "$session_windows" -gt 1 ]; then
  tmux unlink-window -k
  tmux move-window -r -t "$current_session" 2>/dev/null || true
  exit 0
fi

replacement="$(tmux list-sessions -F '#{session_id}' | grep -vxF "$current_session" | head -n 1 || true)"

if [ -n "$replacement" ]; then
  tmux switch-client -t "$replacement"
fi

exec tmux kill-session -t "$current_session"
