# Actions Catalog

`dotfiles actions` is the source of truth for command palette entries. It
combines base tmux actions, safe dotfiles commands, and `dotfiles open` targets.

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
