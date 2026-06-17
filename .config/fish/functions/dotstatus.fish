function dotstatus --description "show dotfiles git status"
    set -l dir "$DOTFILES_DIR"
    test -n "$dir"; or set dir "$HOME/dotfiles"

    git -C "$dir" status --short
    git -C "$dir" log --oneline -5
end
