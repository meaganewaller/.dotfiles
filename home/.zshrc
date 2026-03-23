########################################
# Runtime: mise (must be first)
########################################
# Work (Gusto): shims on PATH via ~/.gusto/init.* — skip activate.
# Override: MISE_USE_SHIMS_ONLY=1
if command -v mise >/dev/null 2>&1; then
  if [[ -f "$HOME/.gusto/init.sh" ]] || [[ "${MISE_USE_SHIMS_ONLY:-0}" == "1" ]]; then
    :
  else
    eval "$(mise activate zsh)"
  fi
fi

########################################
# Base PATH
########################################
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/uv-tools/bin:$PATH"

########################################
# Dotfiles bin
########################################
if [[ -n "${DOTFILES_ROOT:-}" ]]; then
  export PATH="$DOTFILES_ROOT/bin:$PATH"
fi

########################################
# Environment loader (optional tools)
########################################
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

########################################
# zsh options
########################################
setopt HIST_IGNORE_ALL_DUPS
setopt APPEND_HISTORY
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

HISTSIZE=1000
SAVEHIST=2000
HISTFILE="$HOME/.zsh_history"


########################################
# Completion
########################################
autoload -Uz compinit
compinit -u

########################################
# Prompt (minimal + git branch)
########################################
parse_git_branch() {
  git branch 2>/dev/null | sed -n 's/* \(.*\)/ (\1)/p'
}

PROMPT='%1~ %F{green}$(parse_git_branch)%f %# '

########################################
# Aliases
########################################
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
[[ -f ~/.bash_secrets ]] && source ~/.bash_secrets

########################################
# Claude Bedrock prevention
########################################
export CLAUDE_CODE_USE_BEDROCK=0
export CLAUDE_USE_BEDROCK=0
export DISABLE_BEDROCK=1

########################################
# tmux auto-start (interactive only)
########################################
if [[ -o interactive ]]; then
  if [[ -z "$TMUX" ]] && [[ -z "$SSH_CONNECTION" ]] \
     && command -v tmux >/dev/null 2>&1 \
     && [[ -z "$SETUP_SCRIPT_RUNNING" ]] \
     && [[ -z "$NAVIGATION_ALIAS_RUNNING" ]]; then
    exec tmux new-session -A -s main
  fi
fi
