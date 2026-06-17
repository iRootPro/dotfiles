# Dotfiles Strategy

The current approach is intentionally simple: plain Git repository plus an
idempotent installer that creates symlinks. This keeps the system transparent
and easy to debug while still being portable across machines.

## Common Approaches

| Tool | Best For | Tradeoff |
|---|---|---|
| Plain Git + install script | Transparent personal dotfiles | You maintain templates/secrets yourself |
| GNU Stow | Minimal symlink farm | No package/secrets/bootstrap layer |
| Dotbot | Declarative symlink bootstrap | Adds YAML/tooling layer |
| yadm | Git directly over `$HOME` | Easy to accidentally track too much |
| chezmoi | Multi-machine templates and secrets | Different storage model and migration cost |
| Home Manager | Reproducible Nix-managed home | High complexity and Nix commitment |
| Mackup | App settings backup/restore | Too broad for source-controlled dev dotfiles |
| Brewfile | macOS packages/apps | Packages only, not dotfiles |

## Chosen Model

Use this repo as the source of truth for portable configuration:

- Git tracks human-authored, non-secret dotfiles.
- `install.sh` installs dependencies and links configs.
- `Brewfile` declares macOS packages and casks.
- `doctor.sh` validates a machine after install/update.
- Secrets and machine-local state live outside git.

This is close to Dotbot/Stow in spirit, but avoids a migration until there is a
concrete need.

## When To Reconsider

Consider `chezmoi` if host-specific templates and password-manager-backed
secrets become frequent enough to justify a new workflow.

Consider Home Manager/Nix if the goal changes from "portable dotfiles" to
"fully reproducible user environment including packages and services".

Until then, keep this repo boring, explicit, and easy to recover from.
