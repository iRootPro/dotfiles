# Current Worktree Audit

Generated from the current repository status without reading secret-prone file
contents.

## Safe Themed Commits

These can be reviewed and committed as small independent changes:

- `.config/fish/config.fish` and `.zshrc`: shell behavior changes.
- `.config/btop/themes/catppuccin_*.theme`: additional btop themes.
- `.config/tmux/scripts/tmux-pi-*.sh`: Pi/tmux tooling, after script review.
- `.config/tmux/scripts/tmux-session-picker.sh` and `tmux-sessionizer.sh`: tmux session tooling, after checking whether they are still used.

## Audit Before Commit

Do not bulk-add these directories. Inspect filenames and contents first:

- `.config/gh/`: never commit `hosts.yml`; it contains auth tokens.
- `.config/sshm/`: may contain history, backups, hosts, or credentials.
- `.config/talos/`: may contain cluster credentials or kube/talos config.
- `.config/lofi-player/`: verify it contains only portable settings.
- `.config/mc/`: verify it contains only UI/settings, not runtime history.
- `.config/fish/completions/`: distinguish custom completions from generated files.

## Already Covered By Ignore Policy

The root `.gitignore` already excludes common high-risk paths such as:

- `.config/gh/hosts.yml`
- `.config/fish/fish_variables`
- `.config/tmux/plugins/`
- `.config/opencode/node_modules/`
- `.env*`, keys, token/credential-like filenames
- Pi auth/session/runtime files

Run `./doctor.sh` after each batch of changes.
