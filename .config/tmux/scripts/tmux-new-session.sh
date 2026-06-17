#!/usr/bin/env bash
set -euo pipefail

name="${1:-}"
path="${2:-}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

message() {
  tmux display-message "new session: $1"
}

name="$(trim "$name")"
if [ -z "$name" ]; then
  message 'empty name'
  exit 0
fi

if [[ "$name" == *:* ]]; then
  message 'name cannot contain :'
  exit 0
fi

if [ -z "$path" ] || [[ "$path" == *'#{'* ]]; then
  path="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || true)"
fi

if [ -z "$path" ] || ! [ -d "$path" ]; then
  path="$HOME"
fi

path="$(cd "$path" && pwd)"

if tmux has-session -t "=$name" 2>/dev/null; then
  tmux switch-client -t "=$name"
  exit 0
fi

if ! tmux new-session -d -s "$name" -c "$path" 2>/dev/null; then
  message "failed to create '$name'"
  exit 0
fi

tmux switch-client -t "=$name"
