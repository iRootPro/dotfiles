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
export BAT_CONFIG_PATH="$HOME/.config/bat/config"
export DOTFILES_THEME_DIR="$HOME/.local/state/dotfiles/theme"
export BUN_INSTALL="$HOME/.bun"
export FZF_DEFAULT_OPTS="--height 40% --reverse --border"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
[ -f "$DOTFILES_THEME_DIR/env.zsh" ] && source "$DOTFILES_THEME_DIR/env.zsh"

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
  "$BUN_INSTALL/bin"
  "$HOME/.local/bin"
  "/usr/local/go/bin"
  "$GOPATH/bin"
  $path
)
export PATH

# ========== ALIAS ==========
alias nv='nvim'
alias lv='NVIM_APPNAME=lazynvim nvim'
alias lg='lazygit'
alias t='sesh connect'
alias dotup="$DOTFILES_DIR/update.sh"
alias dotclean="$DOTFILES_DIR/cleanup.sh"
alias cat='bat'
alias ls='eza --icons'
alias ll='eza --icons -la'
alias lt='eza --icons --tree --level=2'

if (( $+commands[opencode] )); then
  function opencode() {
    clear
    if [[ -f "$DOTFILES_THEME_DIR/opencode-tui.json" ]]; then
      OPENCODE_TUI_CONFIG="$DOTFILES_THEME_DIR/opencode-tui.json" command opencode "$@"
    else
      command opencode "$@"
    fi
  }
fi

if (( $+commands[lofi-player] )); then
  function lofi-player() {
    if [[ -f "$DOTFILES_THEME_DIR/xdg/lofi-player/config.yaml" ]]; then
      XDG_CONFIG_HOME="$DOTFILES_THEME_DIR/xdg" command lofi-player "$@"
    else
      command lofi-player "$@"
    fi
  }
fi

if (( $+commands[btop] )); then
  function btop() {
    if [[ -f "$DOTFILES_THEME_DIR/btop.conf" ]]; then
      command btop --config "$DOTFILES_THEME_DIR/btop.conf" --themes-dir "$HOME/.config/btop/themes" "$@"
    else
      command btop "$@"
    fi
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
  if [[ -o interactive && -t 0 ]]; then
    source <(fzf --zsh)
  fi

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

# Direnv
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
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
if [[ -f "$DOTFILES_THEME_DIR/starship.toml" ]]; then
  export STARSHIP_CONFIG="$DOTFILES_THEME_DIR/starship.toml"
else
  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
fi
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
