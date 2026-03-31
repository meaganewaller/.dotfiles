#!/usr/bin/env bash
# match-cues.sh - Find cues that match a subject (prompt, command, or file path).
#
# Usage (run):
#   match-cues.sh <mode> [subject]
#   echo "subject" | match-cues.sh <mode>
#
# Usage (source): source match-cues.sh then use cue_content <cue_dir> to get body (no frontmatter).
#
# Mode: prompt | command | file
# Subject: user message (prompt), bash command (command), or file path (file).
# Output: one path per line to cue directories that matched (e.g. ~/.claude/cues/commit).
#
# Cues live in ~/.claude/cues/<name>/cue.md with optional frontmatter:
#   pattern:      regex for prompt
#   commands:     regex for bash command
#   files:        regex for file path
#   scope:        agent | subagent | agent, subagent (default: agent)
#   description:  semantic description for NCD matching (fallback when regex misses)
#   vocabulary:   domain keywords to improve semantic matching
#
# Matching priority:
#   1. Regex match (pattern/commands/files)
#   2. Semantic match via gzip NCD (if description: field exists)
#
# Environment:
#   CUE_SCOPE_FILTER: space-separated scopes to match (default: "agent")
#   CUE_SEMANTIC:     set to "1" to enable semantic matching (default: 1)
#   NCD_THRESHOLD:    similarity threshold for NCD (default: 0.58)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=validate-path.sh
source "${SCRIPT_DIR}/validate-path.sh"

# Output cue body (markdown after frontmatter). Call when script is sourced.
cue_content() {
  local dir="$1"
  local file="${dir}/cue.md"
  [[ -f "$file" ]] || return 1
  awk '/^---$/{c++;next} c>=2' "$file"
}

# Only run matching when executed, not when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return 0
fi

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  echo "Usage: match-cues.sh <prompt|command|file> [subject]" >&2
  exit 1
fi

SUBJECT="${2:-}"
if [[ -z "$SUBJECT" ]]; then
  SUBJECT=$(cat)
fi

if [[ -z "$SUBJECT" ]]; then
  exit 0
fi

CUE_ROOTS=("$CLAUDE_HOME/cues")
if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -d "${CLAUDE_PROJECT_DIR}/.claude/cues" ]]; then
  CUE_ROOTS+=("${CLAUDE_PROJECT_DIR}/.claude/cues")
fi

# Extract frontmatter value for key from a cue.md path. Strips trailing # comment.
# Uses || true so missing keys don't trigger set -e when grep finds nothing.
get_frontmatter() {
  local file="$1"
  local key="$2"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  (awk '/^---$/{c++;next} c==1' "$file" 2>/dev/null | grep -E "^${key}:" | sed -E "s/^${key}: *//" | sed 's/[[:space:]]*#.*$//' | head -1) || true
}

# Test subject against regex. Returns 0 if match.
match_regex() {
  local subject="$1"
  local regex="$2"
  [[ -z "$regex" ]] && return 1
  [[ "$subject" =~ $regex ]] && return 0
  return 1
}

# Test subject against description using semantic matching (gzip NCD).
# Returns 0 if semantically similar.
SEMANTIC_MATCH="$SCRIPT_DIR/semantic-match.sh"
match_semantic() {
  local subject="$1"
  local description="$2"
  local vocabulary="$3"
  [[ -z "$description" ]] && return 1
  [[ ! -x "$SEMANTIC_MATCH" ]] && return 1
  "$SEMANTIC_MATCH" "$subject" "$description" "$vocabulary" 2>/dev/null
}

matched=()
for root in "${CUE_ROOTS[@]}"; do
  [[ ! -d "$root" ]] && continue
  for cue_dir in "$root"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_md="${cue_dir}cue.md"
    [[ ! -f "$cue_md" ]] && continue

    pattern=$(get_frontmatter "$cue_md" "pattern")
    commands=$(get_frontmatter "$cue_md" "commands")
    files=$(get_frontmatter "$cue_md" "files")
    scope=$(get_frontmatter "$cue_md" "scope")
    scope="${scope:-agent}"

    # Check if cue's scope matches any of the required scopes
    # CUE_SCOPE_FILTER defaults to "agent" for backward compatibility
    scope_filter="${CUE_SCOPE_FILTER:-agent}"
    scope_match=0
    for required_scope in $scope_filter; do
      # Handle "agent, subagent" format (with comma)
      if [[ "$scope" == *"$required_scope"* ]]; then
        scope_match=1
        break
      fi
    done
    [[ $scope_match -eq 0 ]] && continue

    # Check if cue's mode matches the current project mode
    # If mode: field is absent, cue fires in all modes (backwards compatible)
    cue_mode=$(get_frontmatter "$cue_md" "mode")
    if [[ -n "$cue_mode" ]]; then
      current_mode=$(get_project_mode)
      mode_match=0
      for m in $(echo "$cue_mode" | tr ',' ' '); do
        m=$(echo "$m" | tr -d '[:space:]')
        if [[ "$m" == "$current_mode" ]]; then
          mode_match=1
          break
        fi
      done
      [[ $mode_match -eq 0 ]] && continue
    fi

    # Extract semantic fields for fallback matching
    description=$(get_frontmatter "$cue_md" "description")
    vocabulary=$(get_frontmatter "$cue_md" "vocabulary")
    semantic_enabled="${CUE_SEMANTIC:-1}"

    case "$MODE" in
      prompt)
        if match_regex "$SUBJECT" "$pattern"; then
          matched+=("$cue_dir")
        elif [[ "$semantic_enabled" == "1" ]] && match_semantic "$SUBJECT" "$description" "$vocabulary"; then
          matched+=("$cue_dir")
        fi
        ;;
      command)
        if match_regex "$SUBJECT" "$commands"; then
          matched+=("$cue_dir")
        elif match_regex "$SUBJECT" "$pattern"; then
          matched+=("$cue_dir")
        elif [[ "$semantic_enabled" == "1" ]] && match_semantic "$SUBJECT" "$description" "$vocabulary"; then
          matched+=("$cue_dir")
        fi
        ;;
      file)
        match_regex "$SUBJECT" "$files" && matched+=("$cue_dir")
        ;;
      *)
        echo "Unknown mode: $MODE" >&2
        exit 1
        ;;
    esac
  done
done

# Deduplicate (same dir from project + global, or command matching both commands and pattern)
seen=""
for dir in "${matched[@]}"; do
  [[ "$seen" == *"|${dir}|"* ]] && continue
  seen="${seen}|${dir}|"
  echo "$dir"
done
