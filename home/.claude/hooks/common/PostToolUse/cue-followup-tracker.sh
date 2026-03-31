#!/usr/bin/env bash
set -euo pipefail

# cue-followup-tracker.sh - Track whether cue guidance was followed
#
# Detects when subsequent tool calls match the intent of recently-fired cues,
# emitting cue_applied events for cue effectiveness measurement.
#
# Heuristics map cue_id → expected tool patterns that indicate guidance was followed.

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

hook_register "cue-followup-tracker"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skip if no session ID (can't correlate with cue markers)
[[ -z "$SESSION_ID" ]] && exit 0
[[ -z "$TOOL_NAME" ]] && exit 0

# Get tool input for command analysis
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# Check for recently fired cues via marker files
# Markers are created by show-cue.sh at /tmp/.claude-devos-cue-${CUE_ID}-${SESSION_ID}
MARKER_PREFIX="/tmp/.claude-devos-cue-"
MARKER_SUFFIX="-${SESSION_ID}"

# Find all cue markers for this session
FIRED_CUES=()
for marker in "${MARKER_PREFIX}"*"${MARKER_SUFFIX}"; do
  [[ -f "$marker" ]] || continue
  # Extract cue_id from marker filename
  cue_id="${marker#"$MARKER_PREFIX"}"
  cue_id="${cue_id%"$MARKER_SUFFIX"}"
  FIRED_CUES+=("$cue_id")
done

# Exit if no cues fired this session
[[ ${#FIRED_CUES[@]} -eq 0 ]] && exit 0

# Heuristics: cue_id → tool patterns that indicate guidance was followed
# Returns: "matched" if tool matches cue intent, empty otherwise
check_cue_applied() {
  local cue_id="$1"
  local tool="$2"
  local tool_input="$3"

  case "$cue_id" in
    file-verification)
      # Cue suggests: verify paths before operations
      # Applied if: using Glob or Read (verification tools)
      [[ "$tool" == "Glob" || "$tool" == "Read" ]] && echo "matched"
      ;;
    commit)
      # Cue suggests: conventional commits, test before push
      # Applied if: git commit with conventional format OR running tests
      if [[ "$tool" == "Bash" ]]; then
        local cmd
        cmd=$(echo "$tool_input" | jq -r '.command // empty')
        # Check for conventional commit pattern or test runs
        if [[ "$cmd" =~ git\ commit.*-m.*(feat|fix|docs|style|refactor|test|chore)\( ]] ||
           [[ "$cmd" =~ (npm|yarn|bundle|pytest|rspec|cargo).*test ]]; then
          echo "matched"
        fi
      fi
      ;;
    testing)
      # Cue suggests: run tests, check edge cases
      # Applied if: running test commands
      if [[ "$tool" == "Bash" ]]; then
        local cmd
        cmd=$(echo "$tool_input" | jq -r '.command // empty')
        if [[ "$cmd" =~ (test|spec|pytest|rspec|jest|mocha|cargo\ test|go\ test|bats) ]]; then
          echo "matched"
        fi
      fi
      ;;
    shell-scripts)
      # Cue suggests: use shellcheck, set -euo pipefail
      # Applied if: running shellcheck
      if [[ "$tool" == "Bash" ]]; then
        local cmd
        cmd=$(echo "$tool_input" | jq -r '.command // empty')
        [[ "$cmd" =~ shellcheck ]] && echo "matched"
      fi
      ;;
    type-checking)
      # Cue suggests: run type checker
      # Applied if: running srb tc, tsc, mypy, etc.
      if [[ "$tool" == "Bash" ]]; then
        local cmd
        cmd=$(echo "$tool_input" | jq -r '.command // empty')
        [[ "$cmd" =~ (srb\ tc|tsc|mypy|pyright) ]] && echo "matched"
      fi
      ;;
    code-quality)
      # Cue suggests: read first, scope check
      # Applied if: reading files before editing
      [[ "$tool" == "Read" ]] && echo "matched"
      ;;
    migration)
      # Cue suggests: reversible migrations
      # Applied if: writing migration file with change method
      if [[ "$tool" == "Write" || "$tool" == "Edit" ]]; then
        local file_path
        file_path=$(echo "$tool_input" | jq -r '.file_path // empty')
        [[ "$file_path" =~ migrate ]] && echo "matched"
      fi
      ;;
    env)
      # Cue suggests: use .env.example, never commit secrets
      # Applied if: editing .env.example
      if [[ "$tool" == "Write" || "$tool" == "Edit" ]]; then
        local file_path
        file_path=$(echo "$tool_input" | jq -r '.file_path // empty')
        [[ "$file_path" =~ \.env\.example ]] && echo "matched"
      fi
      ;;
    large-files)
      # Cue suggests: use offset/limit for large files
      # Applied if: Read with offset/limit params
      if [[ "$tool" == "Read" ]]; then
        if echo "$tool_input" | jq -e '.offset != null or .limit != null' >/dev/null 2>&1; then
          echo "matched"
        fi
      fi
      ;;
    recovery)
      # Cue suggests: investigate before retrying
      # Applied if: using diagnostic tools (Read, Grep, Bash with diagnostic commands)
      [[ "$tool" == "Read" || "$tool" == "Grep" ]] && echo "matched"
      ;;
    adr)
      # Cue suggests: document in ADR format
      # Applied if: writing to architecture/ directory
      if [[ "$tool" == "Write" ]]; then
        local file_path
        file_path=$(echo "$tool_input" | jq -r '.file_path // empty')
        [[ "$file_path" =~ architecture/.*\.md ]] && echo "matched"
      fi
      ;;
    security-reliability)
      # Cue suggests: security-first patterns
      # Applied if: using security scanning or validation
      if [[ "$tool" == "Bash" ]]; then
        local cmd
        cmd=$(echo "$tool_input" | jq -r '.command // empty')
        [[ "$cmd" =~ (brakeman|bundler-audit|npm\ audit|safety) ]] && echo "matched"
      fi
      ;;
    model-first)
      # Cue suggests: model layer first, minimal API
      # Applied if: editing model files before controllers
      if [[ "$tool" == "Edit" || "$tool" == "Write" ]]; then
        local file_path
        file_path=$(echo "$tool_input" | jq -r '.file_path // empty')
        [[ "$file_path" =~ models/ ]] && echo "matched"
      fi
      ;;
    principles)
      # Cue suggests: apply engineering principles
      # Applied if: any deliberate action (hard to detect, skip for now)
      ;;
  esac
}

# Track which cues were applied to avoid duplicate events
# Use different prefix to avoid matching the cue marker glob pattern
APPLIED_FILE="/tmp/.claude-devos-applied-cues-${SESSION_ID}"
touch "$APPLIED_FILE"

# Check each fired cue against current tool use
for cue_id in "${FIRED_CUES[@]}"; do
  # Skip if already marked as applied this session
  if grep -q "^${cue_id}$" "$APPLIED_FILE" 2>/dev/null; then
    continue
  fi

  # Check if this tool use matches the cue's expected pattern
  if [[ -n "$(check_cue_applied "$cue_id" "$TOOL_NAME" "$TOOL_INPUT")" ]]; then
    # Mark as applied
    echo "$cue_id" >> "$APPLIED_FILE"

    # Emit cue_applied event
    PAYLOAD=$(jq -n \
      --arg cue "$cue_id" \
      --arg tool "$TOOL_NAME" \
      '{cue_id: $cue, applied_via_tool: $tool}')

    echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" cue_applied "$PAYLOAD"
  fi
done

exit 0
