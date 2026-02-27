#!/usr/bin/env bash
# show-cue.sh - Output cue content with marker gating and macro support.
#
# Usage:
#   show-cue.sh <cue_dir> [session_id] [trigger_type]
#
# If session_id is provided, creates a marker file to prevent showing the
# same cue twice in one session.
#
# trigger_type: Optional context for how cue was triggered (prompt, bash, file)
#
# Macro support:
#   If the cue directory contains a macro.sh and the frontmatter has
#   "macro: prepend" or "macro: append", the script output is combined
#   with the cue content accordingly.
#
# Output: cue content (with macro output if applicable), or nothing if
#         already shown this session.
#
# Emits: cue_fired event to dev-os-events.jsonl for engagement tracking

set -euo pipefail

CUE_DIR="${1:-}"
SESSION_ID="${2:-${SESSION_ID:-}}"  # Arg takes precedence, then env var
TRIGGER_TYPE="${3:-unknown}"

[[ -z "$CUE_DIR" ]] && exit 0
[[ ! -d "$CUE_DIR" ]] && exit 0

CUE_FILE="${CUE_DIR}/cue.md"
[[ ! -f "$CUE_FILE" ]] && exit 0

CUE_ID=$(basename "${CUE_DIR%/}")

# Check marker - if already shown this session, exit silently
if [[ -n "$SESSION_ID" ]]; then
  MARKER="/tmp/.claude-devos-cue-${CUE_ID}-${SESSION_ID}"
  if [[ -f "$MARKER" ]]; then
    exit 0
  fi
fi

# Extract frontmatter value
get_frontmatter() {
  local key="$1"
  awk '/^---$/{c++;next} c==1' "$CUE_FILE" 2>/dev/null | \
    grep -E "^${key}:" | \
    sed -E "s/^${key}: *//" | \
    sed 's/[[:space:]]*#.*$//' | \
    head -1 || true
}

# Get cue body (content after frontmatter)
get_body() {
  awk '/^---$/{c++;next} c>=2' "$CUE_FILE" 2>/dev/null || true
}

# Check for macro
MACRO_MODE=$(get_frontmatter "macro")
MACRO_SCRIPT="${CUE_DIR}/macro.sh"
MACRO_OUTPUT=""

if [[ -n "$MACRO_MODE" && -x "$MACRO_SCRIPT" ]]; then
  # Execute macro script, passing session_id as env var
  MACRO_OUTPUT=$(SESSION_ID="$SESSION_ID" CUE_DIR="$CUE_DIR" "$MACRO_SCRIPT" 2>/dev/null || true)
fi

# Get cue body
BODY=$(get_body)

# Combine based on macro mode
OUTPUT=""
case "$MACRO_MODE" in
  prepend)
    if [[ -n "$MACRO_OUTPUT" ]]; then
      OUTPUT="${MACRO_OUTPUT}

${BODY}"
    else
      OUTPUT="$BODY"
    fi
    ;;
  append)
    if [[ -n "$MACRO_OUTPUT" ]]; then
      OUTPUT="${BODY}

${MACRO_OUTPUT}"
    else
      OUTPUT="$BODY"
    fi
    ;;
  *)
    OUTPUT="$BODY"
    ;;
esac

# Only output if there's content
if [[ -z "${OUTPUT//[[:space:]]/}" ]]; then
  exit 0
fi

echo "$OUTPUT"

# Create marker after successful output
if [[ -n "$SESSION_ID" ]]; then
  touch "$MARKER" 2>/dev/null || true
fi

# Emit cue_fired event for engagement tracking
EVENTS_LOG="${CLAUDE_EVENTS_LOG:-$HOME/.claude/dev-os-events.jsonl}"
if [[ -w "$(dirname "$EVENTS_LOG")" ]] || [[ -w "$EVENTS_LOG" ]]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  HAS_MACRO="false"
  [[ -n "$MACRO_MODE" ]] && HAS_MACRO="true"
  jq -cn \
    --arg ts "$TIMESTAMP" \
    --arg sid "${SESSION_ID:-unknown}" \
    --arg type "cue_fired" \
    --arg cue "$CUE_ID" \
    --arg trigger "$TRIGGER_TYPE" \
    --argjson has_macro "$HAS_MACRO" \
    '{timestamp: $ts, session_id: $sid, event_type: $type, payload: {cue_id: $cue, trigger_type: $trigger, has_macro: $has_macro}}' \
    >> "$EVENTS_LOG" 2>/dev/null || true
fi
