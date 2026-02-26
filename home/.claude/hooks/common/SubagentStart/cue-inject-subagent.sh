#!/usr/bin/env bash
# SubagentStart: read one stashed cue path, output its content as additionalContext.
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
[[ -z "$SESSION_ID" ]] && exit 0

STASH_DIR="/tmp/.claude-devos-subagent-stash-${SESSION_ID}"
[[ ! -d "$STASH_DIR" ]] && exit 0

# Claim one file (any) atomically: list, take first, read path, remove file
CLAIMED=""
for f in "$STASH_DIR"/*; do
  [[ -f "$f" ]] || continue
  cue_dir=$(cat "$f" 2>/dev/null)
  rm -f "$f" 2>/dev/null || true
  CLAIMED="$cue_dir"
  break
done

[[ -z "$CLAIMED" ]] && exit 0

body=$(awk '/^---$/{c++;next} c>=2' "${CLAIMED}cue.md" 2>/dev/null || true)
[[ -z "$body" ]] && exit 0

jq -n \
  --arg ctx "$body" \
  '{
    hookSpecificOutput: {
      hookEventName: "SubagentStart",
      additionalContext: $ctx
    }
  }'
exit 0
