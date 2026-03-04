#!/usr/bin/env bash
# PreToolUse: Reinforce active principles before Write/Edit actions.
# Keeps principles "warm" through a session instead of one-and-done.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "principle-reinforcer"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null) || SESSION_ID=""
[[ -z "$SESSION_ID" ]] && exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || TOOL=""
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || FILE_PATH=""

# Only act on Write/Edit with a file path
[[ -z "$FILE_PATH" ]] && exit 0

# Active principles file for this session
ACTIVE_PRINCIPLES="/tmp/.claude-active-principles-${SESSION_ID}"

# If no active principles, nothing to reinforce
[[ ! -f "$ACTIVE_PRINCIPLES" ]] && exit 0

# Read active principles (one per line: principle_name|context|timestamp)
mapfile -t PRINCIPLES < "$ACTIVE_PRINCIPLES"
[[ ${#PRINCIPLES[@]} -eq 0 ]] && exit 0

# Determine file context for relevance matching
FILE_EXT="${FILE_PATH##*.}"

RELEVANT_PRINCIPLES=()
REMINDERS=""

for entry in "${PRINCIPLES[@]}"; do
  [[ -z "$entry" ]] && continue
  PRINCIPLE_NAME=$(echo "$entry" | cut -d'|' -f1)
  PRINCIPLE_CONTEXT=$(echo "$entry" | cut -d'|' -f2)

  # Match principles to current action
  case "$PRINCIPLE_NAME" in
    "model-first"|"domain-modeling")
      # Relevant when creating new files or models
      if [[ "$TOOL" == "Write" ]] || [[ "$FILE_PATH" =~ models/ ]] || [[ "$FILE_PATH" =~ migrations/ ]]; then
        RELEVANT_PRINCIPLES+=("$PRINCIPLE_NAME")
        REMINDERS="${REMINDERS}- **Model-first**: Did you sketch the shape before implementing?\n"
      fi
      ;;
    "simplifying-for-change"|"refactoring")
      # Relevant when editing existing code
      if [[ "$TOOL" == "Edit" ]]; then
        RELEVANT_PRINCIPLES+=("$PRINCIPLE_NAME")
        REMINDERS="${REMINDERS}- **Simplify for change**: Make the change easy, then make the easy change\n"
      fi
      ;;
    "testing-with-purpose")
      # Relevant when editing test files or source files
      if [[ "$FILE_PATH" =~ _test\.|_spec\.|test_|spec_ ]] || [[ "$FILE_EXT" == "rb" ]]; then
        RELEVANT_PRINCIPLES+=("$PRINCIPLE_NAME")
        REMINDERS="${REMINDERS}- **Testing**: Is this behavior meaningfully tested?\n"
      fi
      ;;
    "efficiency"|"resource-awareness")
      # Relevant when working with large files or data processing
      if [[ "$FILE_PATH" =~ \.log$|\.jsonl$|\.csv$ ]]; then
        RELEVANT_PRINCIPLES+=("$PRINCIPLE_NAME")
        REMINDERS="${REMINDERS}- **Efficiency**: Use chunked access for large files\n"
      fi
      ;;
    *)
      # Generic principle - include if context matches file path
      if [[ -n "$PRINCIPLE_CONTEXT" ]] && [[ "$FILE_PATH" == *"$PRINCIPLE_CONTEXT"* ]]; then
        RELEVANT_PRINCIPLES+=("$PRINCIPLE_NAME")
        REMINDERS="${REMINDERS}- **${PRINCIPLE_NAME}**: Still applies to this change\n"
      fi
      ;;
  esac
done

# If no relevant principles, exit silently
[[ ${#RELEVANT_PRINCIPLES[@]} -eq 0 ]] && exit 0

# Emit principle_reinforced event
if [[ -x "$HOME/.claude/hooks/dev-os-emit.sh" ]]; then
  PAYLOAD=$(jq -n \
    --arg file "$FILE_PATH" \
    --arg tool "$TOOL" \
    --argjson principles "$(printf '%s\n' "${RELEVANT_PRINCIPLES[@]}" | jq -R . | jq -s '.')" \
    --argjson count "${#RELEVANT_PRINCIPLES[@]}" \
    '{
      file_path: $file,
      tool: $tool,
      principles_reinforced: $principles,
      reinforcement_count: $count
    }')
  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" principle_reinforced "$PAYLOAD" 2>/dev/null || true
fi

# Only inject reminder occasionally (not every single edit)
# Check if we've reminded recently for this principle set
REMINDER_MARKER="/tmp/.claude-principle-reminder-${SESSION_ID}"
if [[ -f "$REMINDER_MARKER" ]]; then
  LAST_REMINDER=$(cat "$REMINDER_MARKER" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  # Only remind every 5 minutes per session
  if (( NOW - LAST_REMINDER < 300 )); then
    exit 0
  fi
fi

# Update reminder timestamp
date +%s > "$REMINDER_MARKER" 2>/dev/null || true

# Output reminder
jq -n \
  --arg ctx "Active principles for this session:\n${REMINDERS}" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $ctx
    }
  }'

exit 0
