# Command Palette

The tmux command palette is the interactive front-end for the `dotfiles` command
center. It reads actions from `dotfiles actions --json`; the tmux script should
only handle picking, previewing, and executing actions.

## Open

- Kitty: `Cmd+Shift+P`
- Alacritty: `Cmd+Shift+P`
- Tmux directly: `~/.config/tmux/scripts/tmux-command-palette.sh`

Inside the palette:

- `Enter` runs the selected action
- `Esc`, `q`, or `Ctrl-C` closes it
- `Ctrl-R` reloads the action list
- Right pane shows the preview

## Action Groups

- Base tmux actions: sessions, windows, splits, rename, smart close, lazygit,
  opencode launch/list.
- `dot:*` actions: run `dotfiles` commands in a popup with log capture.
- `open:*` actions: open repo files/docs in a new tmux window using
  `dotfiles open`.

Interactive editors use new tmux windows, not popups. Short status/update/check
commands use popups so their output is captured in a log.

## Useful Searches

- `doctor` - health checks and compact summary
- `update` - update modes for packages/plugins/tools
- `cleanup` - audit-only cleanup suggestions
- `graphify` - graphify skill and opencode plugin files
- `opencode` - opencode launch/list/config targets
- `pi` - Pi status and runbook

## Add Actions

Prefer changing the source catalogs instead of hard-coding entries in the tmux
script.

- Add a new `dotfiles` command: create `bin/dotfiles-<name>` with metadata
  comments, then run `dotfiles commands --check`.
- Add an editable file/doc: add a row to `config/targets.tsv`, then run
  `dotfiles open --check`.
- Add a curated palette variant: update `bin/dotfiles-actions`, then run
  `dotfiles actions --check`.

Action IDs with arguments encode spaces as `%20`, for example
`dot:update%20packages`.

## Preview Rules

Preview is implemented in `.config/tmux/scripts/tmux-command-palette.sh`.

- `dot:*` previews show label, summary, command, and safety notes.
- `dot:update*` previews warn that updates may be long-running and networked.
- `dot:cleanup` previews state that cleanup is audit-only.
- `open:*` previews show target type, summary, relative path, absolute path, and
  window name.
- Opencode/graphify config previews remind you to restart opencode after editing
  config, skills, or plugins.

## Troubleshooting

If the palette is empty, check:

```bash
dotfiles actions --json
dotfiles actions --check
command -v jq
```

If previews are stale, press `Ctrl-R` in the palette or reload tmux config:

```bash
dotfiles tmux reload
```

If an action fails in a popup, read the log path printed at the bottom of the
popup. Logs live under:

```bash
~/.local/state/tmux-command-palette/
```
