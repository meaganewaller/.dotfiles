#!/usr/bin/env bash
# PostToolUse (Read): Secondary defense - catch resource-limit errors after they occur
# Implements ADR-0008 secondary defense layer
#
# Purpose: When large-file-guard fails to block (e.g., stale session), catch the error
# and reinforce correct behavior to prevent retry loops.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "resource-limit-catcher"

# Only process Read tool results
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL_NAME" != "Read" ]] && exit 0

# Check if this was an error result
TOOL_ERROR=$(echo "$INPUT" | jq -r '.tool_result.error // ""')
[[ -z "$TOOL_ERROR" ]] && exit 0

# Check if it's a resource-limit error (size or token limit)
if [[ "$TOOL_ERROR" == *"exceeds maximum"* ]] || [[ "$TOOL_ERROR" == *"too large"* ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')

  # Log the friction event
  emit_friction "resource-limit" "Read" "$FILE_PATH" "$TOOL_ERROR" \
    "Use tail, grep, or Read with offset/limit parameters" 2>/dev/null || true

  # Detect if this is a session log
  IS_SESSION_LOG="false"
  if [[ "$FILE_PATH" =~ \.claude/projects/.*\.jsonl$ ]]; then
    IS_SESSION_LOG="true"
  fi

  # Build reinforcement message
  if [[ "$IS_SESSION_LOG" == "true" ]]; then
    GUIDANCE="# Session Log Blocked

**Session logs cannot be read directly.** They always exceed context limits.

## Correct Approaches

\`\`\`bash
# Recent entries
tail -50 \"$FILE_PATH\" | jq '.'

# Search for specific content
grep 'pattern' \"$FILE_PATH\" | tail -20

# Count entries by type
jq -s 'group_by(.type) | map({type: .[0].type, count: length})' \"$FILE_PATH\"
\`\`\`

**Do not retry the Read** - it will fail again."
  else
    # Get file info for chunking suggestion
    if [[ -f "$FILE_PATH" ]]; then
      LINES=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ' || echo "unknown")
      SIZE_KB=$(( $(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null || echo 0) / 1024 ))
    else
      LINES="unknown"
      SIZE_KB="unknown"
    fi

    GUIDANCE="# Large File - Use Chunked Reading

**File:** $FILE_PATH
**Size:** ${SIZE_KB}KB, ${LINES} lines

## Read in Chunks

\`\`\`
Read file_path=\"$FILE_PATH\" offset=1 limit=500      # First chunk
Read file_path=\"$FILE_PATH\" offset=501 limit=500   # Second chunk
\`\`\`

## Or Search First

\`\`\`bash
grep -n 'pattern' \"$FILE_PATH\" | head -20  # Find relevant lines
\`\`\`

**Do not retry without offset/limit** - it will fail again."
  fi

  jq -n --arg guidance "$GUIDANCE" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $guidance
    }
  }'
fi

exit 0
