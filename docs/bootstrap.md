# New Machine Bootstrap

This repo is the source of truth for portable, non-secret dotfiles. Runtime state,
auth tokens, credentials, sessions, and machine-local files are restored outside
git.

## macOS

```bash
git clone git@github.com:iRootPro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./doctor.sh
```

`install.sh` installs Homebrew when missing, runs `brew bundle` from `Brewfile`,
links dotfiles into `$HOME`, installs tmux TPM, fonts, and Go dev tools.

If `brew bundle` reports missing apps later:

```bash
brew bundle --file ~/dotfiles/Brewfile
```

## Linux

```bash
git clone git@github.com:iRootPro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
./doctor.sh
```

Linux package support is best-effort for `apt`, `dnf`, and `pacman`. Some tools
are installed via Go/cargo/binary fallback when distro packages are unavailable.

## Manual Restore

After `install.sh`, restore local state that must not live in git:

- Fill `~/.gitconfig` from `.gitconfig.template`.
- Run `gh auth login` if GitHub CLI is needed.
- Restore SSH keys and add them to the agent.
- Restore app/service credentials from the password manager.
- Restore Pi secrets outside this repo's tracked files.
- Reopen terminal/tmux so shell and tmux configs reload cleanly.

## Update Existing Machine

```bash
cd ~/dotfiles
git pull
./install.sh
./doctor.sh
```

Use `./update.sh` for plugin/tool updates and `./cleanup.sh` for audit-only
cleanup suggestions.

`./doctor.sh` should stay green after changes. It catches shell drift, stale
old-clone path references, broken symlinks, and tracked secret-like paths.

## Expected Layout

- Repo lives at `~/dotfiles` on new machines.
- App configs are linked per directory into `~/.config`.
- Fish is the primary login/terminal/tmux shell; Bash is used for scripts.
- Home files like `.zshrc`, `.tmux.conf`, `.skhdrc`, `.yabairc` are symlinked.
- Personal identity and secrets are restored manually or from a password manager.
