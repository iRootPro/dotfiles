#!/usr/bin/env bash
set -euo pipefail

self="$0"
list_all='sesh list -i -t -c'
list_tmux='sesh list -i -t'
list_config='sesh list -i -d -c'
list_zoxide='sesh list -i -d -z'
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'
[ -f "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors" ] && fzf_colors="$(cat "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors")"

strip_ansi() {
  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g'
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

session_from_row() {
  local clean
  clean="$(printf '%s' "$*" | strip_ansi)"
  clean="$(trim "$clean")"
  if [[ "$clean" == *" "* ]]; then
    clean="${clean#* }"
  fi
  trim "$clean"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 && return 0
  printf '%s not found. Install it and retry.\nPress Enter...' "$1"
  IFS= read -r _ || true
  exit 1
}

kill_tmux_session() {
  local session
  session="$(session_from_row "$@")"
  [ -n "$session" ] || exit 0
  tmux has-session -t "=$session" 2>/dev/null || exit 0
  tmux kill-session -t "=$session"
}

if [ "${1:-}" = "kill" ]; then
  shift
  kill_tmux_session "$@"
  exit 0
fi

require_cmd tmux
require_cmd sesh
require_cmd fzf-tmux

selected="$($list_all | fzf-tmux -p 72%,56% \
  --ansi \
  --no-sort \
  --border \
  --border-label=' sesh · all ' \
  --prompt='sessions › ' \
  --header='enter switch · c-a all · c-t tmux · c-c config · c-z zoxide · c-d kill' \
  --info=inline-right \
  --highlight-line \
  --pointer='▌' \
  --marker='✓' \
  --preview='$HOME/.config/tmux/scripts/tmux-sesh-preview.sh {}' \
  --preview-window='right:44%,border-left,wrap' \
  --color="$fzf_colors" \
  --bind="ctrl-a:change-border-label( sesh · all )+change-prompt(sessions › )+reload($list_all)" \
  --bind="ctrl-t:change-border-label( sesh · tmux )+change-prompt(tmux › )+reload($list_tmux)" \
  --bind="ctrl-c:change-border-label( sesh · config )+change-prompt(config › )+reload($list_config)" \
  --bind="ctrl-z:change-border-label( sesh · zoxide )+change-prompt(zoxide › )+reload($list_zoxide)" \
  --bind="ctrl-d:execute-silent($self kill {})+reload($list_all)")" || exit 0

[ -n "$selected" ] || exit 0

exec sesh connect "$selected"
