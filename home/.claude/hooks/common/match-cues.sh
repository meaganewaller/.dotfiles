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
#   pattern:  regex for prompt
#   commands: regex for bash command
#   files:    regex for file path
#   scope:    agent (default) | teammate | subagent (v1: we only consider agent)

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
    [[ "$scope" != "agent" ]] && continue

    case "$MODE" in
      prompt)
        match_regex "$SUBJECT" "$pattern" && matched+=("$cue_dir")
        ;;
      command)
        if match_regex "$SUBJECT" "$commands"; then
          matched+=("$cue_dir")
        elif match_regex "$SUBJECT" "$pattern"; then
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
