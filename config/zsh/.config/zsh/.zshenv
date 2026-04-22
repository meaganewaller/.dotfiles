export LANG='en_US.UTF-8'

_has() {
  type "$1" &>/dev/null
}

_run() {
  if (_has "$1"); then
    "$@"
  else
    printf '\033[33;1mSkipped\033[m\n'
  fi
}

# API tokens for mise/Homebrew/etc. (generate: DOTFILES_ROOT/bin/generate-api-keys --refresh)
[[ -f ${HOME}/.config/dotfiles/secrets.env ]] && source ${HOME}/.config/dotfiles/secrets.env

export EXPORTS_DIR="$HOME/.config/exports"

# Create exports directory if it doesn't exist
[ ! -d "$EXPORTS_DIR" ] && mkdir -p "$EXPORTS_DIR"

load_exports() {
  if [ -d "$EXPORTS_DIR" ]; then
    # Only source files that exist and are readable
    for export_file in "$EXPORTS_DIR"/*; do
      if [ -f "$export_file" ] && [ -r "$export_file" ]; then
        source "$export_file"
      fi
    done
  fi
}

edit_exports() {
  local file=${1:-main}
  local filepath="$EXPORTS_DIR/$file"

  # Create the file if it doesn't exist
  [ ! -f "$filepath" ] && touch "$filepath"

  ${EDITOR:-nvim} "$filepath"
}

reload_exports() {
  load_exports
  echo "Exports reloaded from $EXPORTS_DIR"
}

# Load exports on startup (only if directory exists and has files)
if [ -d "$EXPORTS_DIR" ] && [ "$(ls -A "$EXPORTS_DIR" 2>/dev/null)" ]; then
  load_exports
fi
