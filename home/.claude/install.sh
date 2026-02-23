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

merge_hooks() {
  local common_dir="$DOTFILES_ROOT/home/.claude/hooks/common"
  local profile_dir="$DOTFILES_ROOT/home/.claude/hooks/$PROFILE"
  local dest_dir="$HOME/.claude/hooks"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge hooks (common + $PROFILE) -> $dest_dir"
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
      log "Linked hook $rel"
    done < <(find "$dir" -type f -print0 2>/dev/null)
  done
}

merge_commands() {
  local common_dir="$DOTFILES_ROOT/home/.claude/commands/common"
  local profile_dir="$DOTFILES_ROOT/home/.claude/commands/$PROFILE"
  local dest_dir="$HOME/.claude/commands"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge commands (common + $PROFILE) -> $dest_dir"
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
      log "Linked command $rel"
    done < <(find "$dir" -type f -print0 2>/dev/null)
  done
}

merge_rules() {
  local common_dir="$DOTFILES_ROOT/home/.claude/rules/common"
  local profile_dir="$DOTFILES_ROOT/home/.claude/rules/$PROFILE"
  local dest_dir="$HOME/.claude/rules"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge rules (common + $PROFILE) -> $dest_dir"
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
      log "Linked rule $rel"
    done < <(find "$dir" -type f -print0 2>/dev/null)
  done
}

merge_contexts() {
  local common_dir="$DOTFILES_ROOT/home/.claude/contexts/common"
  local profile_dir="$DOTFILES_ROOT/home/.claude/contexts/$PROFILE"
  local dest_dir="$HOME/.claude/contexts"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge contexts (common + $PROFILE) -> $dest_dir"
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
      log "Linked context $rel"
    done < <(find "$dir" -type f -print0 2>/dev/null)
  done
}

merge_agents() {
  local common_manifest="$DOTFILES_ROOT/home/.claude/common.manifest.json"
  local profile_manifest="$DOTFILES_ROOT/home/.claude/$PROFILE.manifest.json"
  local agents_dir_src="$DOTFILES_ROOT/home/.claude/agents"
  local agents_dir_dest="$HOME/.claude/agents"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge agents (common + $PROFILE manifest) -> $agents_dir_dest"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    log "jq is required to merge agent manifests; install with: brew install jq"
    return 1
  fi

  [[ -f "$common_manifest" ]] || { log "Missing $common_manifest"; return 1; }

  local second_input
  if [[ -f "$profile_manifest" ]]; then
    second_input="$profile_manifest"
  else
    second_input=<(echo '{"agents":[]}')
  fi

  mkdir -p "$agents_dir_dest"
  local merged
  merged=$(jq -s '(.[0].agents // []) + (.[1].agents // []) | unique | .[]' -r "$common_manifest" "$second_input") || return 1

  while IFS= read -r agent; do
    [[ -n "$agent" ]] || continue
    local src="$agents_dir_src/${agent}.md"
    local dest="$agents_dir_dest/${agent}.md"
    if [[ -f "$src" ]]; then
      make_symlink "$src" "$dest"
      log "Linked agent $agent"
    else
      log "Missing agent source: $src (skipping)"
    fi
  done <<< "$merged"
}


merge_config
merge_hooks
merge_skills
merge_commands
merge_rules
merge_contexts
merge_agents
