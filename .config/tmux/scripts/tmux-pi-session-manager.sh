#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"
status_script="${TMUX_PI_STATUS_SCRIPT:-$HOME/.config/tmux/scripts/tmux-pi-status.sh}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'
[ -f "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors" ] && fzf_colors="$(cat "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors")"

die_pause() {
  printf '\n%s Press Enter...' "$1"
  IFS= read -r _ || true
}

require_status_script() {
  if [ -x "$status_script" ]; then
    return
  fi

  printf 'Pi status script not found: %s\n' "$status_script"
  die_pause 'Press Enter to continue'
  exit 1
}

color_for_status() {
  case "$1" in
    error) printf '\033[31;1m' ;;
    attention) printf '\033[33;1m' ;;
    working) printf '\033[36m' ;;
    done) printf '\033[32m' ;;
    dead) printf '\033[31m' ;;
    idle|*) printf '\033[90m' ;;
  esac
}

collect_rows() {
  require_status_script

  local data agg
  data="$($status_script list)" || true
  [ -n "$data" ] || return 0

  agg="$(printf '%s\n' "$data" | awk -F '\t' '
    {
      sid = $1
      name = $2
      status = $7
      if (!(sid in seen)) {
        seen[sid] = 1
        order[++order_count] = sid
        first_pane[sid] = $6
        first_window[sid] = $4
        session_name[sid] = name
      }
      total[sid] = total[sid] + 1
      if (status == "attention") attention[sid] = attention[sid] + 1
      else if (status == "error") error[sid] = error[sid] + 1
      else if (status == "working") working[sid] = working[sid] + 1
      else if (status == "done") done[sid] = done[sid] + 1
      else if (status == "dead") dead[sid] = dead[sid] + 1
      else idle[sid] = idle[sid] + 1
    }
    END {
      for (i = 1; i <= order_count; i++) {
        sid = order[i]
        a = attention[sid] + 0
        e = error[sid] + 0
        w = working[sid] + 0
        d = done[sid] + 0
        i2 = idle[sid] + 0
        de = dead[sid] + 0
        if (a > 0) pr = 1
        else if (e > 0) pr = 2
        else if (w > 0) pr = 3
        else if (d > 0) pr = 4
        else if (i2 > 0) pr = 5
        else if (de > 0) pr = 6
        else pr = 7
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", pr, sid, first_pane[sid], first_window[sid], session_name[sid], a, e, w, d, i2, de
      }
    }
  ')"

  while IFS=$'\t' read -r priority session_id pane_id window_id session_name attention error working done_count idle dead; do
    [ -n "$session_id" ] || continue

    local status="idle"
    if [ "$attention" -gt 0 ]; then
      status="attention"
    elif [ "$error" -gt 0 ]; then
      status="error"
    elif [ "$working" -gt 0 ]; then
      status="working"
    elif [ "$done_count" -gt 0 ]; then
      status="done"
    elif [ "$idle" -gt 0 ]; then
      status="idle"
    elif [ "$dead" -gt 0 ]; then
      status="dead"
    fi

    local summary=""
    ((attention > 0)) && summary+="$(color_for_status attention)$attention\033[0m "
    ((error > 0)) && summary+="$(color_for_status error)$error\033[0m "
    ((working > 0)) && summary+="$(color_for_status working)󰔟$working\033[0m "
    ((done_count > 0)) && summary+="$(color_for_status done)$done_count\033[0m "
    ((idle > 0)) && summary+="$(color_for_status idle)󰒲$idle\033[0m "
    ((dead > 0)) && summary+="$(color_for_status dead)󰅖$dead\033[0m "

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$priority" "$session_id" "$pane_id" "$window_id" "$session_name" "$summary"
  done <<<"$agg" | sort -t $'\t' -k1,1n -k5,5
}

preview() {
  require_status_script
  local target_session="${1:-}"
  [ -n "$target_session" ] || exit 0

  local data session_name=''
  data="$($status_script list)" || true

  if [ -z "$data" ]; then
    printf 'No Pi panes found.\n'
    return
  fi

  session_name="$(tmux list-sessions -F '#{session_id}\t#{session_name}' 2>/dev/null | awk -F '\t' -v sid="$target_session" '$1==sid { print $2; exit }')"
  [ -n "$session_name" ] || session_name="$target_session"

  local bold='\033[1m' reset='\033[0m'
  printf '%bPi session%b %s (%s)%b\n' "$bold" "$reset" "$session_name" "$target_session" "$reset"

  local attention=0 error=0 working=0 done_count=0 idle=0 dead=0 total=0

  printf 'Agents: '
  while IFS=$'\t' read -r session_id session_name_value window_id window_index window_name pane_id _status icon _priority pane_path pane_cmd pane_title summary; do
    [ "$session_id" = "$target_session" ] || continue

    total=$((total + 1))
    case "$_status" in
      attention) attention=$((attention + 1)) ;;
      error)     error=$((error + 1)) ;;
      working)   working=$((working + 1)) ;;
      done)      done_count=$((done_count + 1)) ;;
      idle)      idle=$((idle + 1)) ;;
      dead)      dead=$((dead + 1)) ;;
      *)         idle=$((idle + 1)) ;;
    esac

    local color status_label
    color="$(color_for_status "$_status")"
    status_label="${_status}"
    [ "$status_label" = "attention" ] && status_label='needs input'

    local path_short="$pane_path"
    if [[ "$path_short" == "$HOME"* ]]; then
      path_short="~${path_short#$HOME}"
    fi
    if [ ${#path_short} -gt 58 ]; then
      path_short="…${path_short: -57}"
    fi

    printf '%s %b%s%b %-22s %s  %b%s%b\n' \
      "$color" "$icon" "$status_label$reset" "$path_short" "$window_id:$window_name" "$color" "${summary:-waiting}" "$reset"
  done <<<"$data"

  if [ "$total" -eq 0 ]; then
    printf 'No active Pi agents in this session.\n'
    return
  fi

  printf '\n%sAgents:%s %d\n' "$bold" "$reset" "$total"
  printf '%sSummary:%s %b%s%b ' "$bold" "$reset" "$(color_for_status attention)" "attention:$attention" "$reset"
  printf '%berror:%d%b ' "$(color_for_status error)" "$error" "$reset"
  printf '%bworking:%d%b ' "$(color_for_status working)" "$working" "$reset"
  printf '%bdone:%d%b ' "$(color_for_status done)" "$done_count" "$reset"
  printf '%bidle:%d%b ' "$(color_for_status idle)" "$idle" "$reset"
  printf '%bdead:%d%b\n' "$(color_for_status dead)" "$dead" "$reset"
}

open_session() {
  local session_id="${1:-}"
  local pane_id="${2:-}"
  [ -n "$session_id" ] || exit 0

  if ! tmux has-session -t "$session_id" 2>/dev/null; then
    die_pause "Session not found: $session_id"
    exit 0
  fi

  tmux switch-client -t "$session_id"
  if [ -n "$pane_id" ] && tmux list-panes -t "$session_id" -F '#{pane_id}' 2>/dev/null | grep -qx "$pane_id"; then
    tmux select-pane -t "$pane_id" 2>/dev/null || true
  fi
}

case "$mode" in
  rows) collect_rows ;;
  preview) preview "${2:-}" ;;
  open) open_session "${2:-}" "${3:-}" ;;
  *)
    require_status_script

    rows="$(collect_rows)"
    if [ -z "$rows" ]; then
      printf 'No PI sessions with agents found.\n'
      printf 'Press Enter to continue...' >/dev/tty
      IFS= read -r _ < /dev/tty || true
      exit 0
    fi

    selected="$(printf '%s\n' "$rows" | FZF_DEFAULT_OPTS= fzf \
      --ansi \
      --delimiter=$'\t' \
      --with-nth=5,6 \
      --prompt='pi session manager> ' \
      --header=$'SESSION                          AGENTS\nEnter: switch to session  •  Ctrl-R: refresh  •  Esc: close' \
      --border \
      --border-label=' Pi session manager ' \
      --reverse \
      --height=100% \
      --info=inline-right \
      --color="$fzf_colors" \
      --preview-window='right:62%,border-left,wrap' \
      --preview="$self preview {2}" \
      --bind="ctrl-r:reload($self rows)" )" || exit 0

    [ -n "$selected" ] || exit 0

    session_id="$(printf '%s' "$selected" | awk -F '\t' '{print $2}')"
    pane_id="$(printf '%s' "$selected" | awk -F '\t' '{print $3}')"

    open_session "$session_id" "$pane_id"
    ;;
esac
