#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'
[ -f "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors" ] && fzf_colors="$(cat "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors")"

die_pause() {
  printf '\n%s Press Enter...' "$1"
  IFS= read -r _ || true
}

list_sessions() {
  local current=""
  current="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"

  tmux list-sessions -F '#{session_id}	#{session_name}	#{session_windows}	#{session_attached}	#{session_created_string}' |
    while IFS=$'\t' read -r id name windows attached created; do
      local marker="  " attached_label=""
      [ "$id" = "$current" ] && marker="● "
      [ "$attached" != "0" ] && attached_label=" • attached"
      printf '%s\t%s%s\t%s windows%s\t%s\n' "$id" "$marker" "$name" "$windows" "$attached_label" "$created"
    done
}

new_session() {
  printf '\033[1mNew tmux session\033[0m\n\n'
  printf 'path: %s\n' "$PWD"
  printf 'name: '
  IFS= read -r session || exit 0
  [ -z "$session" ] && exit 0

  if tmux new-session -d -s "$session" -c "$PWD"; then
    tmux switch-client -t "$session"
  else
    die_pause 'Failed to create session.'
  fi
}

rename_session() {
  local target="${1:-}"
  [ -z "$target" ] && target="$(tmux display-message -p '#{session_id}')"

  local current_name
  current_name="$(tmux display-message -p -t "$target" '#{session_name}')"

  printf '\033[1mRename tmux session\033[0m\n\n'
  printf 'current: %s\n' "$current_name"
  printf 'new name: '
  IFS= read -r session || exit 0
  [ -z "$session" ] && exit 0

  if ! tmux rename-session -t "$target" "$session"; then
    die_pause 'Failed to rename session.'
  fi
}

kill_session() {
  local target="${1:-}"
  [ -z "$target" ] && exit 0

  local current replacement
  current="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"

  if [ "$target" = "$current" ]; then
    replacement="$(tmux list-sessions -F '#{session_id}' | grep -vxF "$target" | head -n 1 || true)"
    if [ -n "$replacement" ]; then
      tmux switch-client -t "$replacement"
    fi
  fi

  tmux kill-session -t "$target" 2>/dev/null || true
}

pick_session() {
  local selected target
  selected="$(
    list_sessions | fzf \
      --delimiter=$'\t' \
      --with-nth=2,3,4 \
      --prompt='tmux session> ' \
      --header='SESSION                 WINDOWS        CREATED\nEnter: switch  •  Ctrl-N: new  •  Ctrl-R: rename  •  Ctrl-D: kill' \
      --border \
      --border-label=' Tmux sessions ' \
      --reverse \
      --height=100% \
      --color="$fzf_colors" \
      --preview-window='right:55%,border-left' \
      --preview='printf "Windows:\n"; tmux list-windows -t '\''{1}'\'' -F "  #{window_index}: #{window_name}  [#{pane_current_command}]  #{pane_current_path}" 2>/dev/null' \
      --bind="ctrl-n:become($self new)" \
      --bind="ctrl-r:become($self rename '{1}')" \
      --bind="ctrl-d:execute-silent($self kill '{1}')+reload($self list)"
  )" || exit 0

  target="${selected%%$'\t'*}"
  [ -n "$target" ] && tmux switch-client -t "$target"
}

case "$mode" in
  list) list_sessions ;;
  new) new_session ;;
  rename) rename_session "${2:-}" ;;
  kill) kill_session "${2:-}" ;;
  pick|*) pick_session ;;
esac
