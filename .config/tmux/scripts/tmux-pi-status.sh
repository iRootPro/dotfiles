#!/usr/bin/env bash
set -euo pipefail

mode="${1:-session}"
target="${2:-}"

# Heuristic tmux-side Pi status detector.
# It intentionally does not read Pi session files; it only inspects tmux panes.

pane_has_pi() {
  local pane_id="$1" pane_pid="$2" pane_cmd="$3" pane_title="$4" window_name="$5"

  case "$pane_title" in
    π*|pi*|Pi*) return 0 ;;
  esac
  case "$window_name" in
    pi|Pi|*pi*) return 0 ;;
  esac
  case "$pane_cmd" in
    pi|node) ;;
    *) return 1 ;;
  esac

  if command -v pgrep >/dev/null 2>&1 && pgrep -P "$pane_pid" -af '(^|[/ ])pi( |$)|pi-coding-agent|@earendil-works/pi-coding-agent' >/dev/null 2>&1; then
    return 0
  fi

  # One level deeper catches: shell -> pi -> helper process.
  local child
  while IFS= read -r child; do
    [ -n "$child" ] || continue
    if pgrep -P "$child" -af '(^|[/ ])pi( |$)|pi-coding-agent|@earendil-works/pi-coding-agent' >/dev/null 2>&1; then
      return 0
    fi
  done < <(pgrep -P "$pane_pid" 2>/dev/null || true)

  return 1
}

pane_status() {
  local pane_id="$1" pane_dead="$2"

  if [ "$pane_dead" != "0" ]; then
    printf 'dead'
    return
  fi

  local text last12 last20
  text="$(tmux capture-pane -p -t "$pane_id" -S -80 2>/dev/null || true)"
  last12="$(printf '%s\n' "$text" | tail -12)"
  last20="$(printf '%s\n' "$text" | tail -20)"

  # Keep these checks intentionally narrow: old/user text in the pane can contain
  # words like "error", so only the recent tail should drive status.
  if printf '%s\n' "$last12" | grep -Eiq 'working|thinking|running|executing|processing|⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏'; then
    printf 'working'
  elif printf '%s\n' "$last20" | grep -Eiq 'needs[ _-]?attention|needs input|press enter|confirm|continue\?|proceed\?|approval|required|разреш|подтверд'; then
    printf 'attention'
  elif printf '%s\n' "$last12" | grep -Eq '(^|[[:space:]])(Error:|ERROR|Failed|failed:|Exception|Traceback|panic:|exit status|command failed)'; then
    printf 'error'
  elif printf '%s\n' "$last12" | grep -Eiq 'done|complete|completed|finished|успешно|готово'; then
    printf 'done'
  else
    printf 'idle'
  fi
}

status_icon() {
  case "$1" in
    error) printf '' ;;
    attention) printf '' ;;
    working) printf '󰔟' ;;
    done) printf '' ;;
    dead) printf '󰅖' ;;
    idle|*) printf '󰒲' ;;
  esac
}

status_priority() {
  case "$1" in
    attention) printf '1' ;;
    error) printf '2' ;;
    working) printf '3' ;;
    done) printf '4' ;;
    idle) printf '5' ;;
    dead) printf '6' ;;
    *) printf '9' ;;
  esac
}

pane_summary() {
  local pane_id="$1"
  tmux capture-pane -p -t "$pane_id" -S -120 2>/dev/null | awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    {
      line = trim($0)
      gsub(/\r/, "", line)
      if (line == "") next
      lines[++n] = line
    }
    END {
      for (i = n; i >= 1; i--) {
        l = lines[i]
        gsub(/[[:cntrl:]]/, "", l)
        if (l ~ /^[─━═-]{10,}$/) continue
        if (l ~ /^(Took|Elapsed) [0-9.]+s$/) continue
        if (l ~ /^[0-9]+s\)?$/) continue
        if (l ~ /^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏] .*Working/) continue
        if (l ~ /^\(no output\)$/) continue
        if (l ~ /^[$❯›]/) continue
        if (l ~ /^(~|\/Users\/|\/)[[:print:]]* \([^)]*\)$/) continue
        if (l ~ /^Git .* synced$/ || l ~ /^(Commit|Author|Changes|Remote):/) continue
        if (l ~ /^[↑↓].*gpt-.*(high|medium|low)/) continue
        if (l ~ /^ /) continue
        gsub(/\t/, " ", l)
        if (length(l) > 120) l = substr(l, 1, 117) "…"
        print l
        exit
      }
    }'
}

scan_panes() {
  tmux list-panes -a -F '#{session_id}	#{session_name}	#{window_id}	#{window_index}	#{window_name}	#{pane_id}	#{pane_pid}	#{pane_current_command}	#{pane_title}	#{pane_dead}	#{pane_current_path}' 2>/dev/null |
    while IFS=$'\t' read -r session_id session_name window_id window_index window_name pane_id pane_pid pane_cmd pane_title pane_dead pane_path; do
      if pane_has_pi "$pane_id" "$pane_pid" "$pane_cmd" "$pane_title" "$window_name"; then
        local status icon priority summary
        status="$(pane_status "$pane_id" "$pane_dead")"
        icon="$(status_icon "$status")"
        priority="$(status_priority "$status")"
        summary="$(pane_summary "$pane_id")"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$session_id" "$session_name" "$window_id" "$window_index" "$window_name" "$pane_id" "$status" "$icon" "$priority" "$pane_path" "$pane_cmd" "$pane_title" "$summary"
      fi
    done
}

aggregate() {
  awk -F '\t' '
    BEGIN { total=0 }
    $1 != "" {
      total++
      count[$7]++
    }
    END {
      if (total == 0) exit 0
      out = "π"
      if (count["error"] > 0) out = out " " count["error"]
      if (count["attention"] > 0) out = out " " count["attention"]
      if (count["working"] > 0) out = out " 󰔟" count["working"]
      if (count["idle"] > 0) out = out " 󰒲" count["idle"]
      if (count["done"] > 0) out = out " " count["done"]
      if (count["dead"] > 0) out = out " 󰅖" count["dead"]
      print out
    }'
}

aggregate_label() {
  awk -F '\t' '
    BEGIN { total=0 }
    $1 != "" { total++; count[$7]++ }
    END {
      if (total == 0) exit 0
      if (count["error"] > 0) print " error ×" count["error"]
      else if (count["attention"] > 0) print " needs input ×" count["attention"]
      else if (count["working"] > 0) print "󰔟 working ×" count["working"]
      else if (count["idle"] > 0) print "󰒲 idle ×" count["idle"]
      else if (count["done"] > 0) print " done ×" count["done"]
      else if (count["dead"] > 0) print "󰅖 dead ×" count["dead"]
    }'
}

all_sessions_bar() {
  local max_segments="${TMUX_PI_STATUS_MAX_SESSIONS:-5}"
  cached_panes | awk -F '\t' '
    function short_name(name) {
      gsub(/^ +| +$/, "", name)
      if (length(name) > 14) return substr(name, 1, 13) "…"
      return name
    }
    $1 != "" {
      id=$1
      name[id]=$2
      seen[id]=1
      count[id,$7]++
    }
    END {
      for (id in seen) {
        label=short_name(name[id])
        if (count[id,"error"] > 0) {
          priority=1; seg="#[fg=red,bold] " label ":" count[id,"error"]
        } else if (count[id,"attention"] > 0) {
          priority=2; seg="#[fg=yellow,bold] " label ":" count[id,"attention"]
        } else if (count[id,"working"] > 0) {
          priority=3; seg="#[fg=cyan]󰔟 " label ":" count[id,"working"]
        } else if (count[id,"idle"] > 0) {
          priority=4; seg="#[fg=brightblack]󰒲 " label ":" count[id,"idle"]
        } else if (count[id,"done"] > 0) {
          priority=5; seg="#[fg=green] " label ":" count[id,"done"]
        } else if (count[id,"dead"] > 0) {
          priority=6; seg="#[fg=red]󰅖 " label ":" count[id,"dead"]
        } else next
        printf "%d\t%s\n", priority, seg
      }
    }' | sort -n | head -n "$max_segments" | awk -F '\t' '
      BEGIN { out="" }
      {
        if (out != "") out = out " #[fg=brightblack]| "
        out = out $2
      }
      END {
        if (out != "") print "#[fg=magenta,bold]π #[default]" out "#[default]"
      }'
}

cache_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || printf '0'
}

cached_panes() {
  local cache ttl now mtime tmp
  cache="${TMPDIR:-/tmp}/tmux-pi-status-${UID:-$(id -u)}.tsv"
  ttl="${TMUX_PI_STATUS_TTL:-2}"
  now="$(date +%s)"

  if [ -f "$cache" ]; then
    mtime="$(cache_mtime "$cache")"
    if [ $((now - mtime)) -lt "$ttl" ]; then
      cat "$cache"
      return
    fi
  fi

  tmp="${cache}.$$"
  scan_panes >"$tmp" || true
  mv "$tmp" "$cache"
  cat "$cache"
}

case "$mode" in
  list)
    cached_panes
    ;;
  session)
    [ -n "$target" ] || target="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
    cached_panes | awk -F '\t' -v target="$target" '$1 == target || $2 == target' | aggregate
    ;;
  window)
    [ -n "$target" ] || target="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
    summary="$(cached_panes | awk -F '\t' -v target="$target" '$3 == target' | aggregate)"
    [ -n "$summary" ] && printf ' %s' "$summary"
    ;;
  picker)
    [ -n "$target" ] || exit 0
    summary="$(cached_panes | awk -F '\t' -v target="$target" '$1 == target || $2 == target' | aggregate)"
    [ -n "$summary" ] && printf '%s' "$summary" || printf '-'
    ;;
  label)
    [ -n "$target" ] || exit 0
    summary="$(cached_panes | awk -F '\t' -v target="$target" '$1 == target || $2 == target' | aggregate_label)"
    [ -n "$summary" ] && printf '%s' "$summary" || printf 'no pi'
    ;;
  bar)
    all_sessions_bar
    ;;
  *)
    cached_panes | aggregate
    ;;
esac
