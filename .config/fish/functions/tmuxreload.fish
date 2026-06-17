function tmuxreload --description "reload tmux config"
    if not set -q TMUX
        echo "tmuxreload: not inside tmux" >&2
        return 1
    end

    tmux source-file "$HOME/.config/tmux/tmux.conf"
    tmux display-message "tmux config reloaded"
end
