# Dotfiles Commit Policy

Keep commits small, themed, and safe to apply on a new machine.

## Commit Workflow

```bash
git status --short
git diff
git add <related files only>
git diff --cached
git diff --cached --check
git commit -m "Short focused message"
```

Before committing, verify that staged files contain no secrets, auth state,
runtime databases, logs, or generated dependency directories.

## Commit Always

- Portable app configs: `nvim`, `tmux`, `kitty`, `fish/config.fish`, `starship`,
  `bat`, `btop`, `sesh`.
- Custom scripts under `.config/tmux/scripts/`.
- Docs and runbooks.
- Templates and examples, such as `.gitconfig.template`.
- Curated package lists like `Brewfile`.

## Audit Before Commit

- `.config/gh/`, excluding auth files.
- `.config/sshm/`, excluding history, backups, private hosts, or credentials.
- `.config/talos/`, because Talos/Kubernetes configs often contain secrets.
- `.config/mc/`, `.config/lofi-player/`, and generated completions.
- Any file copied from an app's live config directory.

## Never Commit

- Tokens, OAuth credentials, cookies, sessions, private keys, kubeconfigs.
- `.env*`, `*.pem`, `*.key`, `*token*`, `*credentials*`.
- `.config/fish/fish_variables`.
- `.config/gh/hosts.yml`.
- `.config/tmux/plugins/`.
- `.config/opencode/node_modules/`, package lock/runtime dependency state.
- Logs, backups, pid/socket files, caches.
- Pi auth/session/runtime files.

## Commit Granularity

Prefer these commit shapes:

- `Add btop themes`
- `Update fish aliases`
- `Improve tmux session picker`
- `Add macOS Brewfile`
- `Document new machine bootstrap`

Avoid broad commits like `Update dotfiles` unless the change is only mechanical
cleanup across many files.

## Current Dirty Tree Audit

When the worktree is dirty, sort changes before committing:

- Shell config changes: `.config/fish/config.fish`, `.zshrc`.
- Theme additions: `.config/btop/themes/`.
- New app configs: audit directory contents first.
- New tmux scripts: check syntax and executable bit.

Run `./doctor.sh` after installation or larger changes.
