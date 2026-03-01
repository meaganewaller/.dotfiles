#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/github/meaganewaller/.dotfiles}"
exec "$DOTFILES_ROOT/home/.claude/governance/bin/provenance-verify.sh" "$@"
