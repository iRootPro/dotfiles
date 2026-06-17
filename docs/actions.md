# Actions Catalog

`dotfiles actions` is the source of truth for command palette entries. It
combines base tmux actions, safe dotfiles commands, and `dotfiles open` targets.
For interactive usage and troubleshooting, see
[command-palette.md](command-palette.md).

Useful commands:

```bash
dotfiles actions
dotfiles actions --json
dotfiles actions --markdown
dotfiles actions --check
```

The tmux command palette reads `dotfiles actions --json` and only handles action
execution. Labels and summaries should be adjusted in `dotfiles-actions`,
`dotfiles-open`, or command metadata rather than hard-coded in the tmux script.

Action IDs with spaces in arguments use `%20`, for example
`dot:update%20packages`. `open:*` actions are generated from file/doc targets in
`config/targets.tsv`.
