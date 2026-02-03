#!/usr/bin/env bash
set -euo pipefail

log() { printf '[install] %s\n' "$*"; }
die() { printf '[install] ERROR: %s\n' "$*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$ROOT"

[[ -f "$ROOT/.env" ]] && source "$ROOT/.env"

DOTFILES_PROFILE="${DOTFILES_PROFILE:-work}"
DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) DOTFILES_PROFILE="$2"; shift 2 ;;
    --dry-run) DOTFILES_DRY_RUN=1; shift ;;
    *) die "Unknown arg: $1" ;;
  esac
done

export DOTFILES_PROFILE DOTFILES_DRY_RUN

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

command_available() { command -v "$1" >/dev/null 2>&1; }
running_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

link_dotfiles() {
  local args=(--profile "$DOTFILES_PROFILE")
  [[ "$DOTFILES_DRY_RUN" -eq 1 ]] && args+=(--dry-run)
  "$ROOT/bin/link-dotfiles" "${args[@]}"
}

load_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

log "Profile: $DOTFILES_PROFILE"
link_dotfiles

if running_macos; then
  load_brew_shellenv

  if ! command_available brew; then
    die "brew missing; should have been installed by bootstrap"
  fi

  BREW_COMMON="$ROOT/bootstrap/Brewfile.common"
  BREW_PROFILE="$ROOT/bootstrap/Brewfile.$DOTFILES_PROFILE"

  if [[ "$DOTFILES_DRY_RUN" -eq 0 ]]; then
    brew bundle --file="$BREW_COMMON"
    brew bundle --file="$BREW_PROFILE"
  else
    log "Dry-run: brew bundle --file=$BREW_COMMON"
    log "Dry-run: brew bundle --file=$BREW_PROFILE"
  fi
fi

log "Install complete."
