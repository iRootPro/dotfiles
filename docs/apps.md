# Apps Catalog

`config/apps.tsv` is the curated inventory of packages and GUI apps used by
these dotfiles. `Brewfile` remains the macOS installer source; the catalog adds
tiers, categories, summaries, and installed/missing status.

Useful commands:

```bash
dotfiles apps
dotfiles apps --missing
dotfiles apps --tier core
dotfiles apps --category terminal
dotfiles apps --kind cask
dotfiles apps --markdown
dotfiles apps --json
dotfiles apps --check
```

Tiers:

- `core`: baseline terminal/editor setup expected on every machine.
- `dev`: development tools for the main workstation workflow.
- `optional`: extras and fallback shell integrations.

When adding a Homebrew package or cask, add it to both `Brewfile` and
`config/apps.tsv`, then run `dotfiles apps --check`.
