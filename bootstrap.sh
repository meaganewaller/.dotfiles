#!/usr/bin/env bash
set -euo pipefail

PROFILE="${DOTFILES_PROFILE:-work}"
DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

exec "${ROOT}/install.sh" --profile "${PROFILE}" --dry-run "${DOTFILES_DRY_RUN}"
