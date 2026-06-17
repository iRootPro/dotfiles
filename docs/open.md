# Open Targets

`dotfiles open` is a shortcut for opening common repo-local configs and docs.
It only points at non-secret files in this repository.

Useful commands:

```bash
dotfiles open
dotfiles open fish
dotfiles open tmux
dotfiles open apps
dotfiles open brewfile --print
dotfiles open --json
dotfiles open --check
```

Editor resolution order:

- `$DOTFILES_EDITOR`
- `$EDITOR`
- `nvim`
- `vim`
- `vi`

When adding a target, update `config/targets.tsv`, then run
`dotfiles open --check`.
