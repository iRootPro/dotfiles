# --- Environment ---
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -gx BAT_CONFIG_PATH "$HOME/.config/bat/config"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx FZF_DEFAULT_OPTS "--height 40% --reverse --border"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"

# --- PATH ---
fish_add_path "$HOME/go/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path "$BUN_INSTALL/bin"
fish_add_path "$HOME/.local/bin"

# --- Homebrew ---
eval (/opt/homebrew/bin/brew shellenv)

# --- Shell Integrations ---
starship init fish | source
zoxide init fish | source
direnv hook fish | source
fzf --fish | source

# --- Aliases ---
alias nv="nvim"
alias lv='NVIM_APPNAME=nvim-lazy nvim'
alias dotup="$HOME/Downloads/dotfiles/update.sh"
alias dotclean="$HOME/Downloads/dotfiles/cleanup.sh"
alias cat="bat"
alias ls="eza --icons"
alias ll="eza --icons -la"
alias lt="eza --icons --tree --level=2"
