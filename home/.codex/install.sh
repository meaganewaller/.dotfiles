#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export DOTFILES_ROOT="$ROOT"

PROFILE="${DOTFILES_PROFILE:-work}"
CODEX_INSTALL_DRY_RUN="${CODEX_INSTALL_DRY_RUN:-0}"

source "$ROOT/bin/make-symlink"

log() {
  if [[ "$CODEX_INSTALL_DRY_RUN" -eq 1 ]]; then
    printf '[codex install (dry)] %s\n' "$*"
  else
    printf '[codex install] %s\n' "$*"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        log "Missing value for --profile"
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --dry-run) CODEX_INSTALL_DRY_RUN=1; shift ;;
    *) log "Unknown arg: $1"; exit 1 ;;
  esac
done

log "Profile: $PROFILE"

# Managed allowlist only. Runtime/state files remain local and unmanaged.
# Never touch files like auth.json, sessions, caches, or other Codex-generated state.
map_dest_rel() {
  local rel="$1"
  case "$rel" in
    .config/.codex/*)
      printf ".codex/%s" "${rel#.config/.codex/}"
      ;;
    *)
      printf "%s" "$rel"
      ;;
  esac
}

link_allowlisted() {
  local rel="$1"
  local src="$DOTFILES_ROOT/home/$rel"
  local dest_rel
  dest_rel="$(map_dest_rel "$rel")"
  local dest="$HOME/$dest_rel"

  if [[ "$CODEX_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would link $rel -> $dest_rel"
    return 0
  fi

  make_symlink "$src" "$dest"
  log "Linked $rel -> $dest_rel"
}

sync_allowlisted_dir_files() {
  local rel_dir="$1"
  local src_dir="$DOTFILES_ROOT/home/$rel_dir"

  [[ -d "$src_dir" ]] || return 0

  while IFS= read -r -d '' f; do
    local rel_file
    rel_file="${f#"$DOTFILES_ROOT/home/"}"
    link_allowlisted "$rel_file"
  done < <(find "$src_dir" -type f -print0)
}

link_allowlisted ".codex/config.toml"

if [[ -f "$DOTFILES_ROOT/home/.codex/AGENTS.md" ]]; then
  link_allowlisted ".codex/AGENTS.md"
fi

sync_allowlisted_dir_files ".codex/devos"

log "Done. Managed Codex config synced (allowlist only)."
