#!/usr/bin/zsh

#-----------------------------------------------
###/* Note...
###     XDG_CONFIG_HOME, XDG_DATA_HOME, and XDG_CACHE_HOME
###     in linux mint defaults to the XDG standard
###     so do not need to be explicitly set.
###
###     Ideally, only set XDG_... values when they explicitly do not match the standard
###     The following defaults, per specification, are implemented by the XDG objects:

###    $XDG_CACHE_HOME="$HOME/.cache"
###    $XDG_CONFIG_HOME="$HOME/.config"
###    $XDG_CONFIG_DIRS="/etc/xdg"
###    $XDG_DATA_HOME="$HOME/.local/share"
###    $XDG_DATA_DIRS="/usr/local/share/:/usr/share/"
###    $XDG_RUNTIME_DIR.
###    $XDG_STATE_HOME="$HOME/.local/state"
###

#------------------------------------
###     zsh specific shell variables

# Set up shell history in $ZDOTDIR
export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=10000
export SAVEHIST=10000

setopt HIST_SAVE_NO_DUPS

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=${HOME}/.config}
export ZDOTDIR=${ZDOTDIR:=${XDG_CONFIG_HOME}/zsh}
source $ZDOTDIR/.zshenv
