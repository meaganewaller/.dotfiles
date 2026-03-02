#!/usr/bin/env bash
# dotfiles installer
# Usage: bash install.sh [--profile <name>] [--dry-run] [--yes]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$ROOT"

source "$ROOT/lib/common.sh"

parse_args "$@"

log "Profile: $DOTFILES_PROFILE"

ensure_mise
mise install
mise run brew:bootstrap
$ROOT/home/.local/bin/dotfiles link --profile "$DOTFILES_PROFILE"

log "Install complete."
