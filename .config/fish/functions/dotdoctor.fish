function dotdoctor --description "run dotfiles doctor"
    set -l dir "$DOTFILES_DIR"
    test -n "$dir"; or set dir "$HOME/dotfiles"
    command "$dir/doctor.sh" $argv
end
