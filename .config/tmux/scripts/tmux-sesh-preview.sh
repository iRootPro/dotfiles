#!/usr/bin/env bash
set -euo pipefail

selected="${*:-}"
[ -n "$selected" ] || exit 0

strip_ansi() {
  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g'
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

shorten_home() {
  local value="$1"
  if [[ "$value" == "$HOME"* ]]; then
    value="~${value#$HOME}"
  fi
  printf '%s' "$value"
}

clean="$(printf '%s' "$selected" | strip_ansi)"
clean="$(trim "$clean")"

# sesh list entries are rendered as "<icon> <name>" when icons are enabled.
session="$clean"
if [[ "$clean" == *" "* ]]; then
  session="${clean#* }"
  session="$(trim "$session")"
fi

if [ -n "$session" ] && tmux has-session -t "=$session" 2>/dev/null; then
  printf '\033[1m%s\033[0m\n\n' "$session"

  tmux display-message -p -t "=$session:" 'active: #{pane_current_command}' 2>/dev/null
  tmux display-message -p -t "=$session:" 'path: #{pane_current_path}' 2>/dev/null |
    while IFS= read -r line; do
      printf '%s\n' "$(shorten_home "$line")"
    done

  windows="$(tmux list-windows -t "=$session" -F '#{window_index}:#{window_name}' 2>/dev/null | paste -sd ', ' -)"
  [ -n "$windows" ] && printf 'windows: %s\n' "$windows"
  exit 0
fi

exec sesh preview "$selected"
