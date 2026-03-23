# ~/.bashrc
# shellcheck shell=bash
# Non-login interactive shell config

#######################################
# Core Environment
#######################################

GPG_TTY="$(tty)"
export GPG_TTY
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s histappend checkwinsize 2>/dev/null || true

# API tokens (generate: bin/generate-api-keys --refresh in dotfiles repo)
# shellcheck disable=SC1090,SC1091
[[ -f "${HOME}/.config/dotfiles/secrets.env" ]] && . "${HOME}/.config/dotfiles/secrets.env"

#######################################
# mise (runtime authority)
# MUST be first on PATH
#######################################
# Work (Gusto): shims on PATH — skip activate (same signal as zsh: ~/.gusto/init.sh).
# Override: MISE_USE_SHIMS_ONLY=1

if command -v mise >/dev/null 2>&1; then
  if [[ -f "$HOME/.gusto/init.sh" ]] || [[ "${MISE_USE_SHIMS_ONLY:-0}" == "1" ]]; then
    :
  else
    eval "$(mise activate bash)"
  fi
fi

#######################################
# Base PATH (after mise)
#######################################

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/uv-tools/bin:$PATH"

#######################################
# lesspipe
#######################################

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

#######################################
# Prompt
#######################################

parse_git_branch() {
  git branch 2>/dev/null | sed -n 's/* \(.*\)/ (\1)/p'
}

PS1='\W\[\033[32m\]$(parse_git_branch)\[\033[00m\] \$ '

#######################################
# ls + grep color
#######################################

if [ -x /usr/bin/dircolors ]; then
  eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

#######################################
# Load exports FIRST (sets DOTFILES_ROOT)
#######################################

if [ -f ~/.bash_exports ]; then
  # shellcheck disable=SC1090,SC1091
  . ~/.bash_exports
fi

#######################################
# Dotfiles bin (depends on DOTFILES_ROOT)
#######################################

if [ -n "${DOTFILES_ROOT:-}" ]; then
  export PATH="$DOTFILES_ROOT/bin:$PATH"
fi

#######################################
# Aliases
#######################################

# shellcheck disable=SC1090,SC1091
[ -f ~/.bash_aliases ] && . ~/.bash_aliases
# shellcheck disable=SC1090,SC1091
[ -f ~/.bash_secrets ] && . ~/.bash_secrets

#######################################
# Bash completion
#######################################

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    # shellcheck disable=SC1091
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    # shellcheck disable=SC1091
    . /etc/bash_completion
  fi
fi

#######################################
# Interactive-only behavior
#######################################

if [[ $- == *i* ]]; then
  bind 'set enable-bracketed-paste off' 2>/dev/null || true
fi

#######################################
# tmux auto-start (non-SSH only)
#######################################

if [[ -z "$SSH_CONNECTION" ]]; then
  if [[ -z "$TMUX" ]] && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1 \
     && [ -z "$SETUP_SCRIPT_RUNNING" ] && [ -z "$NAVIGATION_ALIAS_RUNNING" ]; then
    exec tmux new-session -s "terminal-$(date +%s)"
  fi
fi

#######################################
# Always refresh tmux config
#######################################

tmux source-file ~/.tmux.conf >/dev/null 2>&1 || true
