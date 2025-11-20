#!/usr/bin/zsh

autoload -U bashcompinit
bashcompinit

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source "$ZDOTDIR/aliases.zsh"
# Files in $ZDOTDIR/include allows host-specific configurations.
# For example, these may be files not suitable to be tracked by version control.
if [[ -d "$ZDOTDIR/include/" ]]; then
    for file in $ZDOTDIR/include/*.zsh; do
        source "$file"
    done
fi

source "$ZDOTDIR/completion.zsh"

export HISTFILE="$XDG_DATA_HOME/zsh/history"
export SAVEHIST=100000
export HISTSIZE=200000

# The meaning of these options can be found in man page of `zshoptions`.
setopt EXTENDED_HISTORY  # record command start time
setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicate entries first when trimming history
setopt HIST_FIND_NO_DUPS  # do not display duplicates of a previously found line when searching history
setopt HIST_IGNORE_SPACE  # ignore commands that start with space
setopt HIST_REDUCE_BLANKS  # remove unnecessary blanks
setopt HIST_SAVE_NO_DUPS  # do not save duplicated command
setopt INC_APPEND_HISTORY_TIME  # append command to history file immediately after execution

# To customize prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
[[ ! -f "$ZDOTDIR/.p10k.zsh" ]] || source "$ZDOTDIR/.p10k.zsh"

# Work-specific configurations
[[ -f "$HOME/.gusto/init.sh" ]] && source "$HOME/.gusto/init.sh"
export AWS_PROFILE=developer-exp-eng-gusto-main

# Environment setup
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
