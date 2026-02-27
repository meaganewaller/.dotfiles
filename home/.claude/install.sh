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
  local settings_root="$DOTFILES_ROOT/home/.claude/settings"
  local common_dir="$settings_root/common"
  local profile_dir="$settings_root/$PROFILE"
  local dest="$HOME/.claude/settings.json"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would merge JSONC settings (common + $PROFILE) -> $dest"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    log "jq is required; install with: brew install jq"
    return 1
  fi

  if ! command -v fd &>/dev/null; then
    log "fd is required; install with: brew install fd"
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  # ---------------------------------------------
  # 1. Preserve Claude Code's internal state
  # ---------------------------------------------

  local existing_state="{}"
  if [[ -f "$dest" ]]; then
    # Extract internal state fields that Claude Code manages
    existing_state=$(jq '{
      numStartups,
      installMethod,
      autoUpdates,
      tipsHistory,
      promptQueueUseCount,
      cachedGrowthBookFeatures,
      userID,
      firstStartTime,
      sonnet45MigrationComplete,
      opus45MigrationComplete,
      opusProMigrationComplete,
      thinkingMigrationComplete,
      cachedChromeExtensionInstalled,
      changelogLastFetched,
      autoUpdatesProtectedForNative,
      shiftEnterKeyBindingInstalled,
      hasCompletedOnboarding,
      lastOnboardingVersion,
      projects
    } | with_entries(select(.value != null))' "$dest" 2>/dev/null || echo "{}")
  fi

  # ---------------------------------------------
  # 2. Collect files in deterministic order
  # ---------------------------------------------

  mapfile -t settings_files < <(
    {
      fd -t f -e json -e jsonc . "$common_dir" --exclude permissions 2>/dev/null
      fd -t f -e json -e jsonc . "$common_dir/permissions" 2>/dev/null
      fd -t f -e json -e jsonc . "$profile_dir" --exclude permissions 2>/dev/null
      fd -t f -e json -e jsonc . "$profile_dir/permissions" 2>/dev/null
    } | sort
  )

  if [[ "${#settings_files[@]}" -eq 0 ]]; then
    log "No settings files found under $settings_root"
    return 1
  fi

  # ---------------------------------------------
  # 3. Parse JSONC using single Node process
  # ---------------------------------------------

  parsed_json=$(npx -y -p json5 node -e "
    const fs = require('fs');
    const JSON5 = require('json5');

    process.argv.slice(1).forEach(file => {
      try {
        console.log(JSON.stringify(JSON5.parse(fs.readFileSync(file, 'utf8'))));
      } catch (e) {
        console.log('{}');
      }
    });
  " "${settings_files[@]}")

  # ---------------------------------------------
  # 4. Merge with jq (preserving internal state)
  # ---------------------------------------------

  merged_json=$(echo "$parsed_json" | jq -s --argjson state "$existing_state" '
    # Collect permissions across all layers
    {
      permissions: {
        additionalDirectories: ([.[].permissions.additionalDirectories // [] | .[]] | unique),
        allow: ([.[].permissions.allow // [] | .[]] | unique),
        deny: ([.[].permissions.deny // [] | .[]] | unique)
      }
    }
    *
    # Deep merge everything else (profile overrides common)
    (reduce .[] as $item ({}; . * ($item | del(.permissions))))
    | del(."$schema")
    # Merge in preserved internal state
    * $state
    | walk(if type == "object" then to_entries | sort_by(.key) | from_entries else . end)
  ')

  echo "$merged_json" > "$dest"
  log "Merged JSONC config -> $dest (preserved internal state)"
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


link_cues() {
  local src_dir="$DOTFILES_ROOT/home/.claude/cues"
  local dest_dir="$HOME/.claude/cues"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would link cues -> $dest_dir"
    return 0
  fi

  if [[ ! -d "$src_dir" ]]; then
    log "No cues directory found at $src_dir"
    return 0
  fi

  mkdir -p "$dest_dir"
  for cue_dir in "$src_dir"/*/; do
    [[ -d "$cue_dir" ]] || continue
    local name
    name=$(basename "$cue_dir")
    make_symlink "$cue_dir" "$dest_dir/$name"
    log "Linked cue $name"
  done
}

link_governance() {
  local src_dir="$DOTFILES_ROOT/home/.claude/governance"
  local dest_dir="$HOME/.claude/governance"

  if [[ "$CLAUDE_INSTALL_DRY_RUN" -eq 1 ]]; then
    log "Would link governance -> $dest_dir"
    return 0
  fi

  if [[ ! -d "$src_dir" ]]; then
    log "No governance directory found at $src_dir"
    return 0
  fi

  make_symlink "$src_dir" "$dest_dir"
  log "Linked governance"
}

merge_config
merge_hooks
merge_skills
merge_agents
link_cues
link_governance
