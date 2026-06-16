#!/usr/bin/env bash
set -euo pipefail

selected="${*:-}"
[ -n "$selected" ] || exit 0

bold=$'\033[1m'
dim=$'\033[90m'
blue=$'\033[34m'
green=$'\033[32m'
yellow=$'\033[33m'
reset=$'\033[0m'

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
  printf '%s%s%s\n' "$bold" "$session" "$reset"
  printf '%stmux session%s\n\n' "$blue" "$reset"

  tmux display-message -p -t "=$session:" 'active: #{pane_current_command}' 2>/dev/null
  tmux display-message -p -t "=$session:" 'path: #{pane_current_path}' 2>/dev/null |
    while IFS= read -r line; do
      printf '%s\n' "$(shorten_home "$line")"
    done

  windows="$(tmux list-windows -t "=$session" -F '#{window_index}:#{window_name}' 2>/dev/null | paste -sd ', ' -)"
  [ -n "$windows" ] && printf 'windows: %s\n' "$windows"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  exec sesh preview "$selected"
fi

metadata="$(sesh list -j -t -c -z 2>/dev/null | jq -r --arg name "$session" '
  map(select(.Name == $name)) | first // empty |
  [.Src, .Name, .Path, (.Attached | tostring), (.Windows | tostring), .StartupCommand] | @tsv
' 2>/dev/null || true)"

if [ -z "$metadata" ]; then
  exec sesh preview "$selected"
fi

IFS=$'\t' read -r src name path attached windows startup_command <<<"$metadata"

printf '%s%s%s\n' "$bold" "$name" "$reset"
printf '%s%s%s\n\n' "$blue" "$src" "$reset"

printf '%s%-8s%s %s\n' "$dim" 'path' "$reset" "$(shorten_home "$path")"
printf '%s%-8s%s %s\n' "$dim" 'tmux' "$reset" "${windows:-0} windows · ${attached:-0} attached"
[ -n "$startup_command" ] && printf '%s%-8s%s %s\n' "$dim" 'startup' "$reset" "$startup_command"

if [ -d "$path" ] && git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$path" branch --show-current 2>/dev/null || true)"
  [ -n "$branch" ] || branch="$(git -C "$path" rev-parse --short HEAD 2>/dev/null || true)"

  changed=0
  while IFS= read -r _; do
    changed=$((changed + 1))
  done < <(git -C "$path" status --short 2>/dev/null || true)

  if [ "$changed" -gt 0 ]; then
    printf '%s%-8s%s %s · %s%d changed%s\n' "$dim" 'git' "$reset" "${branch:-unknown}" "$yellow" "$changed" "$reset"
  else
    printf '%s%-8s%s %s · %sclean%s\n' "$dim" 'git' "$reset" "${branch:-unknown}" "$green" "$reset"
  fi
fi

if [ -d "$path" ]; then
  printf '\n%scontents%s\n' "$dim" "$reset"
  if command -v eza >/dev/null 2>&1; then
    eza -1 --icons --color=always --group-directories-first "$path" 2>/dev/null || true
  else
    for item in "$path"/*; do
      [ -e "$item" ] || continue
      printf '%s\n' "$(basename "$item")"
    done
  fi
fi
