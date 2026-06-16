#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-list}"
prefix="${TMUX_OPENCODE_PREFIX:-opencode-}"
command="${TMUX_OPENCODE_COMMAND:-opencode}"
popup_width="${TMUX_OPENCODE_POPUP_WIDTH:-90%}"
popup_height="${TMUX_OPENCODE_POPUP_HEIGHT:-90%}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'

PATH="/opt/homebrew/bin:/usr/local/bin:${HOME:-}/.local/bin:${HOME:-}/.opencode/bin:${PATH:-}"
export PATH

normalize_shell() {
  local preferred resolved
  preferred="${TMUX_OPENCODE_SHELL:-$(tmux show-options -gv default-shell 2>/dev/null || true)}"

  for candidate in "$preferred" "${SHELL:-}" /bin/zsh /bin/bash; do
    [ -n "$candidate" ] || continue
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return
    fi

    resolved="$(command -v "$candidate" 2>/dev/null || true)"
    if [ -n "$resolved" ] && [ -x "$resolved" ]; then
      printf '%s\n' "$resolved"
      return
    fi
  done
}

SHELL="$(normalize_shell)"
export SHELL

session_hash() {
  local out
  if command -v md5sum >/dev/null 2>&1; then
    out="$(printf '%s\n' "$1" | md5sum)"
  elif command -v md5 >/dev/null 2>&1; then
    out="$(printf '%s\n' "$1" | md5 -q)"
  else
    out="$(printf '%s\n' "$1" | shasum)"
  fi
  printf '%s' "${out%% *}" | cut -c1-8
}

session_slug() {
  local name
  name="$(basename "$1")"
  name="$(printf '%s' "$name" | tr -cs '[:alnum:]_.-' '-')"
  name="${name#-}"
  name="${name%-}"
  printf '%s' "${name:-project}"
}

session_name() {
  local path="$1"
  printf '%s%s-%s' "$prefix" "$(session_slug "$path")" "$(session_hash "$path")"
}

display_error() {
  tmux display-message "opencode session manager: $1"
}

list_sessions() {
  local now current current_pane command_name
  now="$(date +%s)"
  current="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
  current_pane="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
  command_name="${command##*/}"
  command_name="${command_name%% *}"

  {
    while IFS= read -r session; do
      [[ "$session" == "$prefix"* ]] || continue

      local state at path opencode_session icon rank marker ago
      state="$(tmux show-options -qv -t "$session" @opencode_state 2>/dev/null || true)"
      at="$(tmux show-options -qv -t "$session" @opencode_state_at 2>/dev/null || true)"
      path="$(tmux show-options -qv -t "$session" @opencode_path 2>/dev/null || true)"
      opencode_session="$(tmux show-options -qv -t "$session" @opencode_session_id 2>/dev/null || true)"
      [ -n "$path" ] || path="$(tmux display-message -p -t "$session" '#{pane_current_path}' 2>/dev/null || true)"

      case "$state" in
        waiting) icon=$'\033[33m●\033[0m waiting'; rank=0 ;;
        idle) icon=$'\033[32m●\033[0m idle   '; rank=1 ;;
        working) icon=$'\033[31m●\033[0m working'; rank=3 ;;
        *) icon=$'\033[90m●\033[0m unknown'; rank=2 ;;
      esac

      marker=' '
      [ "$session" = "$current" ] && marker='●'
      if [ -n "$at" ]; then
        ago="$(( (now - at) / 60 ))m"
      else
        ago='-'
      fi

      printf '%s\t%s\t%s %s\t%s\t%s\t%s\n' \
        "$rank" \
        "$session" \
        "$marker" \
        "$icon" \
        "${path/#$HOME/~}" \
        "$ago" \
        "$opencode_session"
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)

    while IFS='|' read -r session pane pane_cmd path pane_title; do
      [[ "$session" == "$prefix"* ]] && continue
      [ "$pane_cmd" = "$command_name" ] || continue

      local marker icon label state at ago rank
      state="$(tmux show-options -pqv -t "$pane" @opencode_state 2>/dev/null || true)"
      at="$(tmux show-options -pqv -t "$pane" @opencode_state_at 2>/dev/null || true)"
      [ -n "$state" ] || state="$(tmux show-options -qv -t "$session" @opencode_state 2>/dev/null || true)"
      [ -n "$at" ] || at="$(tmux show-options -qv -t "$session" @opencode_state_at 2>/dev/null || true)"

      case "$state" in
        waiting) icon=$'\033[33m●\033[0m waiting'; rank=0 ;;
        idle) icon=$'\033[32m●\033[0m idle   '; rank=1 ;;
        working) icon=$'\033[31m●\033[0m working'; rank=3 ;;
        *) icon=$'\033[32m●\033[0m idle   '; rank=1 ;;
      esac

      if [ -n "$at" ]; then
        ago="$(( (now - at) / 60 ))m"
      else
        ago='manual'
      fi

      marker=' '
      [ "$pane" = "$current_pane" ] && marker='●'
      label="${pane_title:-manual}"

      printf '%s\t%s\t%s %s\t%s\t%s\t%s\n' \
        "$rank" \
        "$pane" \
        "$marker" \
        "$icon" \
        "${path/#$HOME/~}" \
        "$ago" \
        "$label"
    done < <(tmux list-panes -a -F '#{session_name}|#{pane_id}|#{pane_current_command}|#{pane_current_path}|#{pane_title}' 2>/dev/null || true)
  } | sort -n
}

preview_target() {
  local target="${1:-}"
  [ -n "$target" ] || exit 0

  tmux display-message -p -t "$target" \
    $'session\t#{session_name}\nwindow\t#{window_index}:#{window_name}\npane\t#{pane_id}\npath\t#{pane_current_path}\ntitle\t#{pane_title}' 2>/dev/null || true
}

nested_session() {
  tmux list-clients -F '#{session_name}' 2>/dev/null | while IFS= read -r session; do
    [[ "$session" == "$prefix"* ]] || continue
    printf '%s\n' "$session"
    break
  done
}

host_client() {
  tmux list-clients -F '#{client_name}|#{session_name}' 2>/dev/null | while IFS='|' read -r client session; do
    [[ "$session" == "$prefix"* ]] && continue
    printf '%s\n' "$client"
    break
  done
}

launch_session() {
  local path="${1:-$PWD}" origin="${2:-}" session current

  if ! command -v "$command" >/dev/null 2>&1; then
    display_error "$command not found"
    exit 0
  fi

  path="$(cd "$path" && pwd)"
  session="$(session_name "$path")"
  current="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"

  if [[ "$current" == "$prefix"* ]]; then
    display_error 'already inside an OpenCode popup'
    exit 0
  fi

  if ! tmux has-session -t "=$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -c "$path" "clear; exec \"$command\""
    tmux set-option -t "$session" @opencode_state unknown >/dev/null
  fi

  tmux set-option -t "$session" @opencode_path "$path" >/dev/null
  [ -n "$origin" ] && tmux set-option -t "$session" @opencode_origin "$origin" >/dev/null

  tmux switch-client -t "=$session"
}

open_picker_popup() {
  local nested host popup_args sessions
  popup_args=(-w "$popup_width" -h "$popup_height" -E -e "SHELL=$SHELL" -e "PATH=$PATH")

  sessions="$(list_sessions)"
  if [ -z "$sessions" ]; then
    display_error 'no OpenCode sessions; use Cmd+Y to launch one'
    return 0
  fi

  nested="$(nested_session)"
  if [ -n "$nested" ]; then
    tmux detach-client -s "$nested"
    for _ in $(seq 1 100); do
      [ -z "$(nested_session)" ] && break
      sleep 0.05
    done
  fi

  host="$(host_client)"
  tmux set-option -g @opencode_parent "$host" >/dev/null

  if [ -n "$host" ]; then
    tmux display-popup -c "$host" "${popup_args[@]}" "$self" pick || true
  else
    tmux display-popup "${popup_args[@]}" "$self" pick || true
  fi
}

pick_session() {
  local selected target origin parent self_quoted refresh_action

  if ! command -v fzf >/dev/null 2>&1; then
    display_error 'fzf not found'
    exit 0
  fi

  self_quoted="$(printf '%q' "$self")"
  refresh_action="(while sleep 1; do curl -fsS -XPOST \"localhost:\$FZF_PORT\" -d 'reload($self_quoted list-rows)' >/dev/null || break; done) >/dev/null 2>&1 &"

  selected="$(list_sessions | fzf \
    --ansi \
    --delimiter=$'\t' \
    --with-nth=3,4,5 \
    --id-nth=2 \
    --no-sort \
    --track \
    --reverse \
    --cycle \
    --listen=0 \
    --border \
    --border-label=' OpenCode sessions ' \
    --prompt='opencode › ' \
    --header='enter jump · ctrl-r reload · ctrl-x kill · esc cancel' \
    --preview-window='right:42%,border-left,wrap' \
    --preview="$self preview {2}" \
    --bind="start:execute-silent($refresh_action)" \
    --bind="ctrl-r:reload($self list-rows)" \
    --bind="ctrl-x:execute-silent($self kill {2})+reload($self list-rows)" \
    --color="$fzf_colors")" || exit 0

  [ -n "$selected" ] || exit 0
  target="$(printf '%s' "$selected" | cut -f2)"
  [ -n "$target" ] || exit 0

  if [[ "$target" == %* ]]; then
    local target_session
    target_session="$(tmux display-message -p -t "$target" '#{session_name}' 2>/dev/null || true)"
    if [ -n "$target_session" ]; then
      tmux switch-client -t "=$target_session"
      tmux select-window -t "$target" 2>/dev/null || true
      tmux select-pane -t "$target" 2>/dev/null || true
    fi
    exit 0
  fi

  origin="$(tmux show-options -qv -t "$target" @opencode_origin 2>/dev/null || true)"
  parent="$(tmux show-options -gqv @opencode_parent 2>/dev/null || true)"
  if [ -n "$parent" ]; then
    tmux switch-client -c "$parent" -t "=$target"
  else
    tmux switch-client -t "=$target"
  fi
}

kill_session() {
  local target="${1:-}"
  [ -n "$target" ] || exit 0
  [[ "$target" == "$prefix"* ]] || exit 0
  tmux kill-session -t "$target" 2>/dev/null || true
}

set_state() {
  local state="${1:-idle}" opencode_session="${2:-}" session pane_cmd command_name now
  [ -n "${TMUX_PANE:-}" ] || exit 0
  session="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null || true)"
  [ -n "$session" ] || exit 0

  command_name="${command##*/}"
  command_name="${command_name%% *}"
  pane_cmd="$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_command}' 2>/dev/null || true)"
  [[ "$session" == "$prefix"* || "$pane_cmd" = "$command_name" ]] || exit 0

  case "$state" in
    working|waiting|idle|unknown) ;;
    *) state='unknown' ;;
  esac

  now="$(date +%s)"
  tmux set-option -t "$session" @opencode_state "$state" >/dev/null
  tmux set-option -t "$session" @opencode_state_at "$now" >/dev/null
  [ -n "$opencode_session" ] && tmux set-option -t "$session" @opencode_session_id "$opencode_session" >/dev/null

  tmux set-option -p -t "$TMUX_PANE" @opencode_state "$state" >/dev/null
  tmux set-option -p -t "$TMUX_PANE" @opencode_state_at "$now" >/dev/null
  [ -n "$opencode_session" ] && tmux set-option -p -t "$TMUX_PANE" @opencode_session_id "$opencode_session" >/dev/null
}

case "$mode" in
  launch) launch_session "${2:-}" "${3:-}" ;;
  list) open_picker_popup ;;
  list-rows) list_sessions ;;
  preview) preview_target "${2:-}" ;;
  pick) pick_session ;;
  kill) kill_session "${2:-}" ;;
  state) set_state "${2:-idle}" "${3:-}" ;;
  *) open_picker_popup ;;
esac
