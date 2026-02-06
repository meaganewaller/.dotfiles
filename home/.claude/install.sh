#!/usr/bin/env bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export DOTFILES_ROOT="$ROOT"

PROFILE="${DOTFILES_PROFILE:-work}"
CLAUDE_INSTALL_DRY_RUN="${CLAUDE_INSTALL_DRY_RUN:-0}"

source "$ROOT/bin/make-symlink"

log() {
    if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
        printf '[install (dry)] %s\n' "$*"
    else
        printf '[install] %s\n' "$*"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --dry-run) CLAUDE_INSTALL_DRY_RUN=1; shift ;;
        *) log "Unknown arg: $1"; exit 1 ;;
    esac
done

export PROFILE CLAUDE_INSTALL_DRY_RUN

link() {
    if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
        log "Would $*"
    else
        log "Installing $*"
        if [[ "$2" ]]; then
            make_symlink "$DOTFILES_ROOT/home/.claude/$1" "$HOME/.claude/$2"
        else
            make_symlink "$DOTFILES_ROOT/home/.claude/$1" "$HOME/.claude/$1"
        fi
    fi
}

merge_config() {
  local common="$DOTFILES_ROOT/home/.claude/settings/common/config.json"
  local profile="$DOTFILES_ROOT/home/.claude/settings/$PROFILE/config.json"
  local dest="$HOME/.claude/settings.json"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge config (common + $PROFILE) -> $dest"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    log "jq is required to merge config; install with: brew install jq"
    return 1
  fi

  [[ -f "$common" ]] || { log "Missing $common"; return 1; }
  [[ -f "$profile" ]] || { log "Missing $profile"; return 1; }

  mkdir -p "$(dirname "$dest")"
  # jq * does deep merge: nested dicts (e.g. env, permissions) merge by key; profile overrides only on collision
  if jq -s '.[0] * .[1]' "$common" "$profile" > "$dest"; then
    log "Merged config -> $dest"
  else
    log "Failed to merge config"
    return 1
  fi
}

merge_skills() {
  local common_dir="$DOTFILES_ROOT/home/.claude/skills/common"
  local profile_dir="$DOTFILES_ROOT/home/.claude/skills/$PROFILE"
  local dest_dir="$HOME/.claude/skills"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge skills (common + $PROFILE) -> $dest_dir"
    return 0
  fi

  mkdir -p "$dest_dir"

  for dir in "$common_dir" "$profile_dir"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' f; do
      rel="${f#"$dir"/}"
      rel="${rel#/}"
      dest="$dest_dir/$rel"
      make_symlink "$f" "$dest"
      log "Linked skill $rel"
    done < <(find "$dir" -type f -print0 2>/dev/null)
  done
}

merge_config
merge_skills
