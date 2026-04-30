#!/usr/bin/env bash
# dotfiles installer
# Usage: bash install.sh [--profile <name>] [--dry-run] [--yes]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$ROOT"

# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"

parse_args "$@"
validate_profile "$DOTFILES_PROFILE"

log "Profile: $DOTFILES_PROFILE"
export MISE_ENV="${DOTFILES_PROFILE:-work}"
log "MISE_ENV: $MISE_ENV"

# Link global mise config (and miserc -> miserc.<profile>.toml) before install so
# `mise install` uses the same layers as daily shells.
"$ROOT/bin/link-dotfiles" --only-mise --profile "$DOTFILES_PROFILE"

if [[ $DOTFILES_PROFILE == "personal" ]]; then
  log "Personal profile selected. Setting brewfile layers to: base, gui, creative"
  export BREW_LAYERS="base gui creative dev infra"
else
  log "Work profile selected. Setting brewfile layers to: base, gui, dev, infra, work"
  export BREW_LAYERS="base gui dev infra work"
fi

ensure_mise
mise install

if [[ "${DOTFILES_DRY_RUN:-0}" -eq 1 ]]; then
  log "Dry-run mode: skipping brew:bootstrap"
	log "Dry-run mode: skipping fonts:install"
else
  mise run brew:bootstrap
  mise run fonts:install
fi

"$ROOT"/home/.local/bin/dotfiles link --profile "$DOTFILES_PROFILE"

log "Install complete."
