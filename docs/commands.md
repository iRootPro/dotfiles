# Dotfiles Commands

`dotfiles` is the command center for this repository. It wraps the existing
root scripts and Pi helpers without changing their behavior.

Generate the current table with:

```bash
dotfiles commands --markdown
```

| Command | Binary | Summary |
| --- | --- | --- |
| `dotfiles actions [--json\|--markdown\|--check]` | `dotfiles-actions` | List command palette actions |
| `dotfiles apps [--tier TIER] [--category CATEGORY] [--kind KIND] [--status STATUS] [--missing] [--json\|--markdown\|--check]` | `dotfiles-apps` | Show curated app and CLI catalog |
| `dotfiles cleanup` | `dotfiles-cleanup` | Show audit-only cleanup suggestions |
| `dotfiles debug [--print]` | `dotfiles-debug` | Print safe diagnostic snapshot |
| `dotfiles doctor [--summary\|--json]` | `dotfiles-doctor` | Run dotfiles health checks |
| `dotfiles install` | `dotfiles-install` | Install packages and symlink dotfiles |
| `dotfiles open [TARGET] [--print\|--json\|--markdown\|--check]` | `dotfiles-open` | Open curated dotfiles targets in editor |
| `dotfiles pi backup` | `dotfiles-pi-backup` | Back up non-secret Pi config into repo |
| `dotfiles pi restore` | `dotfiles-pi-restore` | Restore non-secret Pi config from repo |
| `dotfiles pi status` | `dotfiles-pi-status` | Show non-secret Pi config status |
| `dotfiles reload` | `dotfiles-reload` | Reload fish and tmux config when available |
| `dotfiles status` | `dotfiles-status` | Show repo status and recent commits |
| `dotfiles tmux reload` | `dotfiles-tmux-reload` | Reload tmux config |
| `dotfiles update [plugins\|packages\|nvim\|tmux\|go\|all]` | `dotfiles-update` | Update plugins, tools, or packages |
