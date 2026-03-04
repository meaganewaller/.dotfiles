#!/usr/bin/env bash
# PreToolUse (Glob|Grep): estimate resource usage before bulk operations
# Warns when operations may return large result sets
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "bulk-operation-estimator"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# ============================================================================
# GLOB ESTIMATION
# ============================================================================
if [[ "$TOOL_NAME" == "Glob" ]]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
  SEARCH_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // "."')

  [[ -z "$PATTERN" ]] && exit 0
  [[ ! -d "$SEARCH_PATH" ]] && exit 0

  # Estimate file count (quick sampling, not full search)
  # Use find with maxdepth to get a quick estimate
  ESTIMATE=0
  SAMPLE_DEPTH=3

  # Convert glob pattern to find pattern (basic conversion)
  FIND_PATTERN="${PATTERN//\*\*/}"
  FIND_PATTERN="${FIND_PATTERN//\*/}"

  if [[ -n "$FIND_PATTERN" ]]; then
    ESTIMATE=$(find "$SEARCH_PATH" -maxdepth "$SAMPLE_DEPTH" -name "*${FIND_PATTERN}*" 2>/dev/null | wc -l | tr -d ' ')
  else
    # Very broad pattern - estimate total files
    ESTIMATE=$(find "$SEARCH_PATH" -maxdepth "$SAMPLE_DEPTH" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Warn if estimate is high
  WARN_THRESHOLD="${RESOURCE_GLOB_WARN_THRESHOLD:-100}"

  if (( ESTIMATE > WARN_THRESHOLD )); then
    # Suggest more specific patterns
    SUGGESTIONS=""
    case "$PATTERN" in
      "**/*")
        SUGGESTIONS="Consider: **/*.rb, **/*.ts, or specific directory like src/**/*"
        ;;
      "**/*.*")
        SUGGESTIONS="Consider: **/*.{ts,tsx} or limit to specific directories"
        ;;
      *"**"*)
        SUGGESTIONS="Add file extension filter or limit directory depth"
        ;;
      *)
        SUGGESTIONS="Consider adding path prefix or file extension filter"
        ;;
    esac

    jq -n \
      --arg estimate "$ESTIMATE" \
      --arg pattern "$PATTERN" \
      --arg suggestions "$SUGGESTIONS" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          additionalContext: ("**Bulk operation warning**: Pattern `\($pattern)` may match ~\($estimate)+ files.\n\n\($suggestions)\n\nLarge result sets consume context window. Consider narrowing the search.")
        }
      }'
  fi
fi

# ============================================================================
# GREP ESTIMATION
# ============================================================================
if [[ "$TOOL_NAME" == "Grep" ]]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
  SEARCH_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // "."')
  OUTPUT_MODE=$(echo "$INPUT" | jq -r '.tool_input.output_mode // "files_with_matches"')
  HEAD_LIMIT=$(echo "$INPUT" | jq -r '.tool_input.head_limit // 0')

  [[ -z "$PATTERN" ]] && exit 0

  # If head_limit is set, they're already limiting
  (( HEAD_LIMIT > 0 && HEAD_LIMIT < 50 )) && exit 0

  # Quick estimate using sampling
  ESTIMATE=0

  if [[ -d "$SEARCH_PATH" ]]; then
    # Sample search - check first 100 files
    SAMPLE_FILES=$(find "$SEARCH_PATH" -type f -name "*.rb" -o -name "*.py" -o -name "*.ts" -o -name "*.js" 2>/dev/null | head -100)
    if [[ -n "$SAMPLE_FILES" ]]; then
      ESTIMATE=$(echo "$SAMPLE_FILES" | xargs grep -l "$PATTERN" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
      # Scale up estimate based on sampling
      TOTAL_FILES=$(find "$SEARCH_PATH" -type f 2>/dev/null | wc -l | tr -d ' ')
      if (( TOTAL_FILES > 100 )); then
        ESTIMATE=$(( ESTIMATE * TOTAL_FILES / 100 ))
      fi
    fi
  fi

  WARN_THRESHOLD="${RESOURCE_GREP_WARN_THRESHOLD:-50}"

  if (( ESTIMATE > WARN_THRESHOLD )); then
    SUGGESTIONS=""
    case "$OUTPUT_MODE" in
      "content")
        SUGGESTIONS="Consider: output_mode=\"files_with_matches\" first, then read specific files. Or add head_limit=20."
        ;;
      *)
        SUGGESTIONS="Consider: adding head_limit=20 or narrowing with glob filter."
        ;;
    esac

    jq -n \
      --arg estimate "$ESTIMATE" \
      --arg pattern "$PATTERN" \
      --arg suggestions "$SUGGESTIONS" \
      '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          additionalContext: ("**Grep may match many files**: Pattern `\($pattern)` estimated ~\($estimate)+ matches.\n\n\($suggestions)\n\nUse head_limit to cap results and preserve context window.")
        }
      }'
  fi
fi

exit 0
