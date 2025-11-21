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

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export EDITOR="cursor --wait"

export DOTFILES_REPO_URL="https://github.com/meaganewaller/.dotfiles.git"
export DOTFILES_TARGET_DIR="$HOME/github/meaganewaller/.dotfiles"
export DOTFILES_PROFILE=work
export GUSTO_SSH_SELF_MANAGED=1

source "$ZDOTDIR/paths.zsh"

# vi: filetype=zsh
