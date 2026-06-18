# --- Environment ---
if not set -q DOTFILES_DIR
    set -l fish_config_dir (dirname (status --current-filename))
    if command -q realpath
        set -gx DOTFILES_DIR (realpath "$fish_config_dir/../..")
    else
        set -gx DOTFILES_DIR "$HOME/dotfiles"
    end
end

set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -gx BAT_CONFIG_PATH "$HOME/.config/bat/config"
set -gx DOTFILES_THEME_DIR "$HOME/.local/state/dotfiles/theme"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx FZF_DEFAULT_OPTS "--height 40% --reverse --border"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
if test -f "$DOTFILES_THEME_DIR/env.fish"
    source "$DOTFILES_THEME_DIR/env.fish"
end
set -gx TALOSCONFIG "$HOME/.config/talos/home-cluster/talosconfig"
set -gx KUBECONFIG "$HOME/.kube/home-talos.yaml"
set -g fish_greeting ""

# --- PATH ---
fish_add_path "$HOME/go/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path "$BUN_INSTALL/bin"
fish_add_path "$HOME/.local/bin"

# --- Homebrew ---
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

# --- Shell Integrations ---
if command -q starship
    starship init fish | source
end

if command -q zoxide
    zoxide init fish | source
end

if command -q direnv
    direnv hook fish | source
end

if command -q fzf
    fzf --fish | source
end

# --- Aliases ---
alias nv="nvim"
alias t="sesh connect"
alias dotup="$DOTFILES_DIR/update.sh"
alias dotclean="$DOTFILES_DIR/cleanup.sh"

if command -q bat
    alias cat="bat"
end

if command -q eza
    alias ls="eza --icons"
    alias ll="eza --icons -la"
    alias lt="eza --icons --tree --level=2"
end

if command -q opencode
    function opencode --wraps opencode --description "Start opencode on a clean terminal screen"
        clear
        if test -f "$DOTFILES_THEME_DIR/opencode-tui.json"
            set -lx OPENCODE_TUI_CONFIG "$DOTFILES_THEME_DIR/opencode-tui.json"
            command opencode $argv
        else
            command opencode $argv
        end
    end
end

if command -q lofi-player
    function lofi-player --wraps lofi-player --description "Start lofi-player with dotfiles theme when available"
        if test -f "$DOTFILES_THEME_DIR/xdg/lofi-player/config.yaml"
            set -lx XDG_CONFIG_HOME "$DOTFILES_THEME_DIR/xdg"
            command lofi-player $argv
        else
            command lofi-player $argv
        end
    end
end

if command -q btop
    function btop --wraps btop --description "Start btop with dotfiles theme when available"
        if test -f "$DOTFILES_THEME_DIR/btop.conf"
            command btop --config "$DOTFILES_THEME_DIR/btop.conf" --themes-dir "$HOME/.config/btop/themes" $argv
        else
            command btop $argv
        end
    end
end
