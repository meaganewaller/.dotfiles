export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export EDITOR="cursor --wait"

export DOTFILES_REPO_URL="https://github.com/meaganewaller/.dotfiles.git"
export DOTFILES_TARGET_DIR="$HOME/github/meaganewaller/.dotfiles"
export DOTFILES_PROFILE=work

source "$ZDOTDIR/paths.zsh"

# vi: filetype=zsh
