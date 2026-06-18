#!/usr/bin/env bash
set -euo pipefail

self="$0"
mode="${1:-pick}"
fzf_colors='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,fg:#cdd6f4,header:#6c7086,info:#6c7086,pointer:#cba6f7,marker:#a6e3a1,fg+:#cdd6f4,prompt:#89b4fa,hl+:#cba6f7,border:#45475a,label:#cba6f7'
[ -f "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors" ] && fzf_colors="$(cat "${DOTFILES_THEME_DIR:-$HOME/.local/state/dotfiles/theme}/fzf-colors")"

dotfiles_bin() {
  if command -v dotfiles >/dev/null 2>&1; then
    command -v dotfiles
  elif [ -x "$HOME/dotfiles/bin/dotfiles" ]; then
    printf '%s\n' "$HOME/dotfiles/bin/dotfiles"
  fi
}

list_dotfiles_actions() {
  local dotfiles
  dotfiles="$(dotfiles_bin)"
  [ -n "$dotfiles" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  "$dotfiles" actions --json 2>/dev/null | jq -r '
    .actions[]
    | .id + "\t" + .label + "\t" + .summary
  ' 2>/dev/null || true
}

list_commands() {
  list_dotfiles_actions
}

popup_fish() {
  local command="$1"
  tmux display-popup -w 88% -h 82% -E "$(printf '%q' "$self") popup $(printf '%q' "$command")" || true
}

run_with_script() {
  local command="$1" log="$2"

  if script --version >/dev/null 2>&1; then
    script -q -a "$log" -c "fish -lc $(printf '%q' "$command")"
  else
    script -q -a "$log" fish -lc "$command"
  fi
}

safe_window_name() {
  local name="$1"
  name="${name//[^[:alnum:]_.-]/-}"
  printf 'dot:%.24s\n' "$name"
}

action_metadata() {
  local action="$1" dotfiles
  dotfiles="$(dotfiles_bin)"
  [ -n "$dotfiles" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  "$dotfiles" actions --json 2>/dev/null | jq -r --arg id "$action" '
    .actions[]
    | select(.id == $id)
    | [.label, .summary]
    | @tsv
  ' 2>/dev/null || true
}

target_metadata() {
  local target="$1" dotfiles
  dotfiles="$(dotfiles_bin)"
  [ -n "$dotfiles" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  "$dotfiles" open --json 2>/dev/null | jq -r --arg id "$target" '
    .targets[]
    | select(.id == $id)
    | [.type, .path, .summary, .absolute_path]
    | @tsv
  ' 2>/dev/null || true
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
  if command -v script >/dev/null 2>&1; then
    run_with_script "$command" "$log"
    status=$?
  else
    fish -lc "$command" 2>&1 | tee -a "$log"
    status=${PIPESTATUS[0]}
  fi
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

preview_action() {
  local action="${1:-}" dotfiles route target root path window_name label summary target_type relpath target_summary abs_path
  [ -n "$action" ] || exit 0

  printf '\033[1;34m%s\033[0m\n\n' "$action"

  case "$action" in
    close)
      printf 'Close the command palette without running anything.\n'
      ;;
    sessions)
      printf 'Open sesh/tmux session picker.\n'
      printf 'Script: ~/.config/tmux/scripts/tmux-sesh-picker.sh\n'
      ;;
    windows)
      printf 'Open tmux window picker.\n'
      printf 'Script: ~/.config/tmux/scripts/tmux-window-picker.sh\n'
      ;;
    new-session)
      printf 'Prompt for a new tmux session name in the current pane directory.\n'
      ;;
    new-window)
      printf 'Create a new tmux window in the current pane directory.\n'
      ;;
    smart-close)
      printf 'Close pane, window, or session safely.\n'
      printf 'Script: ~/.config/tmux/scripts/tmux-smart-close.sh\n'
      ;;
    split-down)
      printf 'Create a horizontal split below in the current pane directory.\n'
      ;;
    split-right)
      printf 'Create a vertical split on the right in the current pane directory.\n'
      ;;
    opencode-launch)
      printf 'Start an opencode session for the current pane directory.\n'
      ;;
    opencode-list)
      printf 'Show existing opencode sessions.\n'
      ;;
    lazygit)
      printf 'Open lazygit in a new tmux window named git.\n'
      ;;
    rename-window)
      printf 'Prompt for the current tmux window name.\n'
      ;;
    rename-session)
      printf 'Prompt for the current tmux session name.\n'
      ;;
    dot:*)
      dotfiles="$(dotfiles_bin)"
      route="${action#dot:}"
      route="${route//%20/ }"
      IFS=$'\t' read -r label summary < <(action_metadata "$action")
      [ -n "${label:-}" ] && printf '%s\n' "$label"
      [ -n "${summary:-}" ] && printf '%s\n' "$summary"
      printf '\nRun dotfiles command in a popup with log capture.\n'
      case "$route" in
        update|update\ *)
          printf 'Warning: update actions can take a while and may use the network.\n'
          ;;
        cleanup)
          printf 'Safety: cleanup is audit-only and does not delete files.\n'
          ;;
      esac
      printf '\n'
      printf 'Command:\n  %s %s\n' "${dotfiles:-dotfiles}" "$route"
      [ "$route" = "debug" ] && printf '  --print\n'
      ;;
    open:*)
      dotfiles="$(dotfiles_bin)"
      target="${action#open:}"
      window_name="$(safe_window_name "$target")"
      if [ -n "$dotfiles" ]; then
        root="$(cd "$(dirname "$(realpath "$dotfiles")")/.." && pwd)"
        path="$($dotfiles open "$target" --print 2>/dev/null || true)"
        IFS=$'\t' read -r target_type relpath target_summary abs_path < <(target_metadata "$target")
        [ -n "${abs_path:-}" ] && path="$abs_path"
      else
        root="$HOME/dotfiles"
        path=""
      fi
      printf 'Open target in a new tmux window.\n\n'
      [ -n "${target_type:-}" ] && printf 'Type:   %s\n' "$target_type"
      [ -n "${target_summary:-}" ] && printf 'About:  %s\n' "$target_summary"
      printf 'Window: %s\n' "$window_name"
      printf 'Root:   %s\n' "$root"
      [ -n "${relpath:-}" ] && printf 'Target: %s\n' "$relpath"
      [ -n "$path" ] && printf 'Path:   %s\n' "$path"
      case "$target" in
        opencode*|graphify-skill)
          printf '\nNote: restart opencode after editing config, skills, or plugins.\n'
          ;;
      esac
      printf '\nCommand:\n  %s open %s\n' "${dotfiles:-dotfiles}" "$target"
      ;;
    *)
      printf 'No preview available for this action.\n'
      ;;
  esac
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
    --preview="$self preview {1}" \
    --preview-window='right:45%:wrap' \
    --color="$fzf_colors")" || exit 0

  [ -n "$selected" ] || exit 0
  action="${selected%%$'\t'*}"
  run_action "$action" || exit 0
}

case "$mode" in
  list) list_commands ;;
  popup) popup_command "${2:-}" ;;
  preview) preview_action "${2:-}" ;;
  run) run_action "${2:-}" || exit 0 ;;
  pick|*) pick_command ;;
esac
