setopt auto_cd
setopt correct
setopt glob_dots
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt list_types
setopt print_eight_bit
setopt share_history

autoload -Uz compinit
zsh-defer compinit -d "$XDG_DATA_HOME/zsh/compdump"

autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars ' -_,.;:"()[]{}@/=|'
zstyle ':zle:*' word-style unspecified

zstyle ':completion:*:default' menu select=1
bindkey '^[[Z' reverse-menu-complete
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

export HISTFILE="$XDG_DATA_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
export HISTSIZE=100000
export SAVEHIST=100000
