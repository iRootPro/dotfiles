function dotcd --description "cd to dotfiles repo"
    set -l dir "$DOTFILES_DIR"
    test -n "$dir"; or set dir "$HOME/dotfiles"
    cd "$dir"
end
