# Agent instructions for dotfiles

## Scope

This repository manages personal dotfiles. Be conservative: do not overwrite user-local settings, secrets, or runtime state unless explicitly asked.

## Commands

- Install/symlink dotfiles: `./install.sh`
- Update packages/plugins: `./update.sh`
- Audit cleanup opportunities only: `./cleanup.sh`
- Sync non-secret Pi config: `./scripts/pi-sync.sh status|backup|restore`

## Safety boundaries

- Do not read or commit secrets:
  - `~/.pi/agent/auth.json`
  - `~/.pi/agent/sessions/`
  - `~/.pi/youtube_credentials/`
  - `.env*`, tokens, OAuth credentials, cookies
- Do not delete files automatically from cleanup suggestions. `cleanup.sh` is audit-only.
- Treat `~/.config` as live config: changes under `.config/` may affect the current machine immediately.
- Preserve existing dirty/untracked user changes; check `git status --short` before broad edits.

## Pi-specific notes

- Pi live config is in `~/.pi/agent`, not `~/.config`.
- This repo stores only non-secret Pi assets under `pi/agent/`.
- Use `pi.md` as the Pi runbook.
- Prefer package version pins in templates for reproducibility; live settings may intentionally be unpinned for rolling updates.

## Style

- Keep docs concise and practical.
- Prefer exact commands that can be copied.
- Prefer small targeted edits over broad rewrites.
