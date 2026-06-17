function dotreload --description "reload fish and tmux dotfiles config"
    source "$HOME/.config/fish/config.fish"

    if set -q TMUX
        tmux source-file "$HOME/.config/tmux/tmux.conf"
        tmux display-message "dotfiles: fish + tmux reloaded"
    else
        echo "dotfiles: fish reloaded"
    end
end
