# ========== ОПРЕДЕЛЕНИЕ ОС ==========
case "$(uname -s)" in
  Darwin) IS_MAC=true ;;
  Linux)  IS_LINUX=true ;;
esac

# ========== ИСТОРИЯ ==========
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# ========== EDITOR ==========
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

# ========== PATH ==========
export PATH="$HOME/.local/bin:$PATH"

# Go
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Tmux session manager
export PATH="$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"

# ========== ALIAS ==========
alias nv='nvim'
alias lg='lazygit'

if [[ -n "$IS_MAC" ]]; then
  alias lc='colorls -lA --sd'
elif [[ -n "$IS_LINUX" ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

# ========== FZF ==========
function fzf-history-search() {
  selected_command=$(fc -l 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' | fzf --height 40% --reverse --prompt="History: ")
  if [[ -n "$selected_command" ]]; then
    LBUFFER="$selected_command"
    zle end-of-line
  fi
  zle reset-prompt
}
zle -N fzf-history-search
bindkey '^R' fzf-history-search

# ========== ЛЕНИВАЯ ЗАГРУЗКА ==========

# Zoxide
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Pass
if (( $+commands[pass] )); then
  function pass() {
    unset -f pass
    command pass "$@"
  }
fi

# Carapace
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  function _carapace_init() {
    unset -f _carapace_init
    eval "$(carapace _carapace 2>/dev/null)"
  }
  compdef _carapace_init carapace
fi

# ========== ZSH SYNTAX HIGHLIGHTING ==========
for f in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -f "$f" ]] && source "$f" && break
done

# ========== ZSH AUTOSUGGESTIONS ==========
for f in \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -f "$f" ]] && source "$f" && break
done

# ========== COMPLETIONS ==========
autoload -U compinit; compinit

# ========== ЛОКАЛЬНЫЕ НАСТРОЙКИ ==========
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ========== STARSHIP ==========
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"
