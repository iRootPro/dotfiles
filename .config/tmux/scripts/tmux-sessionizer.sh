#!/usr/bin/env bash
set -euo pipefail

roots=()
if [ -n "${TMUX_SESSIONIZER_ROOTS:-}" ]; then
  # shellcheck disable=SC2206
  roots=(${TMUX_SESSIONIZER_ROOTS})
else
  roots=("$HOME/Code" "$HOME/Projects" "$HOME/Developer" "$HOME/Downloads" "$HOME/.config")
fi

existing_roots=()
for root in "${roots[@]}"; do
  [ -d "$root" ] && existing_roots+=("$root")
done

[ "${#existing_roots[@]}" -gt 0 ] || {
  printf 'No project roots found. Set TMUX_SESSIONIZER_ROOTS.\nPress Enter...'
  IFS= read -r _ || true
  exit 1
}

list_dirs() {
  if command -v fd >/dev/null 2>&1; then
    fd --type d --max-depth 2 --color never . "${existing_roots[@]}" 2>/dev/null
  else
    find "${existing_roots[@]}" -maxdepth 2 -type d 2>/dev/null
  fi | awk '!seen[$0]++' | sort
}

selected="$(
  list_dirs | fzf \
    --prompt='project> ' \
    --border \
    --border-label=' Projects ' \
    --reverse \
    --height=100% \
    --preview-window='right:55%,border-left' \
    --preview='if command -v eza >/dev/null 2>&1; then eza --icons -la --group-directories-first {} | head -120; else ls -la {} | head -120; fi'
)" || exit 0

[ -n "$selected" ] || exit 0

name="$(basename "$selected")"
name="$(printf '%s' "$name" | tr -c '[:alnum:]_.-' '_')"
[ -n "$name" ] || name="project"

if tmux has-session -t "=$name" 2>/dev/null; then
  tmux switch-client -t "=$name"
else
  tmux new-session -d -s "$name" -c "$selected"
  tmux switch-client -t "=$name"
fi
