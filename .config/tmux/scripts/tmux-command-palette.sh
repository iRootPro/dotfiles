#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'

dotfiles_bin() {
  if command -v dotfiles >/dev/null 2>&1; then
    command -v dotfiles
  elif [ -x "$HOME/dotfiles/bin/dotfiles" ]; then
    printf '%s\n' "$HOME/dotfiles/bin/dotfiles"
  fi
}

list_dotfiles_commands() {
  local dotfiles
  dotfiles="$(dotfiles_bin)"
  [ -n "$dotfiles" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  "$dotfiles" commands --json 2>/dev/null | jq -r '
    .commands[]
    | select(.route != "dotfiles install")
    | select(.route != "dotfiles pi backup")
    | select(.route != "dotfiles pi restore")
    | select(.route != "dotfiles tmux reload")
    | if .route == "dotfiles apps" then
        "dot:apps\tApps\tShow curated app and CLI catalog",
        "dot:apps%20--missing\tMissing apps\tShow missing apps/tools",
        "dot:apps%20--check\tApps check\tValidate app catalog"
      else
        "dot:" + (.route | sub("^dotfiles "; "") | gsub(" "; "%20")) + "\t" + (.route | sub("^dotfiles "; "")) + "\t" + (if .route == "dotfiles reload" then "Reload shell/tmux config" else .summary end)
      end
  ' 2>/dev/null || true
}

list_open_targets() {
  local dotfiles
  dotfiles="$(dotfiles_bin)"
  [ -n "$dotfiles" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  "$dotfiles" open --json 2>/dev/null | jq -r '
    .targets[]
    | select(.type == "file" or .type == "doc")
    | "open:" + .id + "\tOpen " + .id + "\t" + .path + " - " + .summary
  ' 2>/dev/null || true
}

list_commands() {
  cat <<'EOF'
close	Close palette	Exit without running anything
sessions	Sessions switch/create	Open sesh picker
windows	Windows switch/close	Open tmux window picker
new-session	New tmux session	Prompt for session name in current directory
new-window	New tmux window	Create window in current directory
smart-close	Smart close	Close pane, window, or session safely
split-down	Split down	Create horizontal split below
split-right	Split right	Create vertical split on the right
opencode-launch	Opencode launch	Start opencode session for current directory
opencode-list	Opencode list	Show opencode sessions
lazygit	Git lazygit	Open lazygit in a new window
rename-window	Rename window	Prompt for current window name
rename-session	Rename session	Prompt for current session name
EOF
  list_open_targets
  list_dotfiles_commands
}

popup_fish() {
  local command="$1"
  tmux display-popup -w 88% -h 82% -E "$(printf '%q' "$self") popup $(printf '%q' "$command")" || true
}

safe_window_name() {
  local name="$1"
  name="${name//[^[:alnum:]_.-]/-}"
  printf 'dot:%.24s\n' "$name"
}

popup_command() {
  local command="${1:-}" status log_dir log
  [ -n "$command" ] || exit 0

  log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-command-palette"
  mkdir -p "$log_dir"
  log="$log_dir/$(date +%Y%m%d-%H%M%S)-${command//[^[:alnum:]_.-]/_}.log"

  printf '\033[1;34m%s\033[0m\n\n' "$command"
  printf '$ %s\n\n' "$command" >"$log"
  set +e
  fish -lc "$command" 2>&1 | tee -a "$log"
  status=${PIPESTATUS[0]}
  set -e

  printf '\n'
  if [ "$status" -eq 0 ]; then
    printf 'Done (exit 0)\n' | tee -a "$log"
  else
    printf 'Failed (exit %s)\n' "$status" | tee -a "$log"
  fi
  printf 'Log: %s\n' "$log" | tee -a "$log"

  if [ -z "${TMUX_COMMAND_PALETTE_NO_WAIT:-}" ]; then
    printf '\nOpening scrollable log. Scroll to review, q closes popup...\n'
    sleep 0.5
    env LESS= less -R +G "$log" || true
  fi

  exit 0
}

run_action() {
  local action="$1"
  local path window_id
  path="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || printf '%s' "$HOME")"
  window_id="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"

  case "$action" in
    close) exit 0 ;;
    sessions) "$HOME/.config/tmux/scripts/tmux-sesh-picker.sh" || true ;;
    windows) "$HOME/.config/tmux/scripts/tmux-window-picker.sh" || true ;;
    new-session) tmux command-prompt -I "$(basename "$path")" -p 'New session' "run-shell \"$HOME/.config/tmux/scripts/tmux-new-session.sh \\\"%%\\\" \\\"#{pane_current_path}\\\"\"" || true ;;
    new-window) tmux new-window -c "$path" || true ;;
    smart-close) "$HOME/.config/tmux/scripts/tmux-smart-close.sh" || true ;;
    split-down) tmux split-window -c "$path" || true ;;
    split-right) tmux split-window -h -c "$path" || true ;;
    opencode-launch) "$HOME/.config/tmux/scripts/tmux-opencode-session-manager.sh" launch "$path" "$window_id" || true ;;
    opencode-list) "$HOME/.config/tmux/scripts/tmux-opencode-session-manager.sh" list || true ;;
    lazygit) tmux new-window -n git -c "$path" lazygit || true ;;
    rename-window) tmux command-prompt -I '#W' "rename-window '%%'" || true ;;
    rename-session) tmux command-prompt -I '#S' "rename-session '%%'" || true ;;
    dot:*)
      local dotfiles route command
      dotfiles="$(dotfiles_bin)"
      [ -n "$dotfiles" ] || exit 0
      route="${action#dot:}"
      route="${route//%20/ }"
      command="$(printf '%q' "$dotfiles") $route"
      [ "$route" = "debug" ] && command="$command --print"
      popup_fish "$command"
      ;;
    open:*)
      local dotfiles target command window_name root
      dotfiles="$(dotfiles_bin)"
      [ -n "$dotfiles" ] || exit 0
      target="${action#open:}"
      window_name="$(safe_window_name "$target")"
      root="$(cd "$(dirname "$(realpath "$dotfiles")")/.." && pwd)"
      command="$(printf '%q' "$dotfiles") open $(printf '%q' "$target")"
      tmux new-window -n "$window_name" -c "$root" "fish -lc $(printf '%q' "$command")" || true
      ;;
  esac
}

pick_command() {
  local selected action
  selected="$(list_commands | fzf-tmux -p 72%,52% \
    --ansi \
    --delimiter=$'\t' \
    --nth=1,2 \
    --with-nth=2,3 \
    --border \
    --border-label=' commands ' \
    --prompt='run > ' \
    --pointer='>' \
    --marker='+' \
    --info=inline-right \
    --layout=reverse \
    --header='enter run | esc/q/c-c close | c-r reload' \
    --bind="esc:abort,q:abort,ctrl-c:abort,ctrl-r:reload($self list)" \
    --color="$fzf_colors")" || exit 0

  [ -n "$selected" ] || exit 0
  action="${selected%%$'\t'*}"
  run_action "$action" || exit 0
}

case "$mode" in
  list) list_commands ;;
  popup) popup_command "${2:-}" ;;
  run) run_action "${2:-}" || exit 0 ;;
  pick|*) pick_command ;;
esac
