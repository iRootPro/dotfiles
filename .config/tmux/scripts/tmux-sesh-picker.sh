#!/usr/bin/env bash
set -euo pipefail

list_all='sesh list -i -d -t -c'
list_tmux='sesh list -i -d -t'
list_config='sesh list -i -d -c'
list_zoxide='sesh list -i -d -z'

selected="$($list_all | fzf-tmux -p 85%,75% \
  --ansi \
  --no-sort \
  --border \
  --border-label=' sesh ' \
  --prompt='  ' \
  --header='Enter: connect  Ctrl-A: all  Ctrl-T: tmux  Ctrl-C: config  Ctrl-Z: zoxide  Ctrl-D: kill tmux session' \
  --preview='sesh preview {}' \
  --preview-window='right:55%,border-left' \
  --bind="ctrl-a:change-prompt(  )+reload($list_all)" \
  --bind="ctrl-t:change-prompt( tmux )+reload($list_tmux)" \
  --bind="ctrl-c:change-prompt(  )+reload($list_config)" \
  --bind="ctrl-z:change-prompt(  )+reload($list_zoxide)" \
  --bind="ctrl-d:execute-silent(tmux kill-session -t {2..})+reload($list_all)")" || exit 0

[ -n "$selected" ] || exit 0

exec sesh connect "$selected"
