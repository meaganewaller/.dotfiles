#!/usr/bin/env bash
set -euo pipefail

log() { printf '[sketchybar] %s\n' "$*"; }

# -------- paths --------
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
CONFIG_SRC="$DOTFILES_ROOT/home/.config/sketchybar"
CONFIG_DEST="$HOME/.config/sketchybar"

# -------- sanity --------
if ! command -v brew >/dev/null 2>&1; then
  log "brew not found; sketchybar must be installed via Brewfile"
  exit 1
fi

if ! brew list --versions sketchybar >/dev/null 2>&1 && \
   ! brew list --versions felixkratz/formulae/sketchybar >/dev/null 2>&1; then
  log "sketchybar not installed; run brew bundle first"
  exit 1
fi

# -------- ensure config --------
if [[ ! -e "$CONFIG_DEST" ]]; then
  log "Config not linked; linking via link-dotfiles"
  "$DOTFILES_ROOT/bin/link-dotfiles" --profile "${DOTFILES_PROFILE:-work}"
else
  log "Config already present at $CONFIG_DEST"
fi

# -------- service --------
status="$(brew services list 2>/dev/null | awk '$1=="sketchybar"{print $2; exit}')"
if [[ "$status" == "started" ]]; then
  log "sketchybar service already running"
else
  log "Starting sketchybar service"
  brew services start sketchybar >/dev/null
fi

log "Sketchybar setup complete"