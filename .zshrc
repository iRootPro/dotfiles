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

# ========== DOTFILES ==========
if [[ -z "${DOTFILES_DIR:-}" ]]; then
  export DOTFILES_DIR="${${(%):-%N}:A:h}"
fi

# ========== HOMEBREW ==========
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ========== PATH ==========
export GOPATH="$HOME/go"
typeset -U path PATH
path=(
  "$HOME/.opencode/bin"
  "$HOME/.bun/bin"
  "$HOME/.local/bin"
  "/usr/local/go/bin"
  "$GOPATH/bin"
  $path
)
export PATH

# ========== ALIAS ==========
alias nv='nvim'
alias lg='lazygit'
alias t='sesh connect'
alias dotup="$DOTFILES_DIR/update.sh"
alias dotclean="$DOTFILES_DIR/cleanup.sh"

if (( $+commands[opencode] )); then
  function opencode() {
    clear
    command opencode "$@"
  }
fi

if [[ -n "$IS_MAC" ]]; then
  if (( $+commands[eza] )); then
    alias lc='eza --icons -la --group-directories-first'
  elif (( $+commands[colorls] )); then
    alias lc='colorls -lA --sd'
  fi
elif [[ -n "$IS_LINUX" ]]; then
  if ! (( $+commands[pbcopy] )) && (( $+commands[xclip] )); then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi
fi

# ========== FZF ==========
if (( $+commands[fzf] )); then
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
fi

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
autoload -U compinit; compinit
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

# ========== ЛОКАЛЬНЫЕ НАСТРОЙКИ ==========
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ========== STARSHIP ==========
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
