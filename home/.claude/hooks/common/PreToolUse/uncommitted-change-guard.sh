#!/usr/bin/env bash
# PreToolUse: Warn before editing files with uncommitted changes
# Prevents silent loss of in-progress work
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "uncommitted-change-guard"
hook_set_context "$INPUT"

TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
FILE_PATH=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")

json_response() {
  jq -n --arg decision "$1" --arg reason "$2" '{decision:$decision,reason:$reason}'
}

# Only check Edit and Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  json_response "approve" "Not a file modification tool"
  hook_success
  exit 0
fi

# Skip if no file path
if [[ -z "$FILE_PATH" ]]; then
  json_response "approve" "No file path specified"
  hook_success
  exit 0
fi

# Skip if file doesn't exist (new file creation is fine)
if [[ ! -f "$FILE_PATH" ]]; then
  json_response "approve" "New file creation"
  hook_success
  exit 0
fi

# Find the git repo root for this file
REPO_ROOT=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || {
  # Not in a git repo
  json_response "approve" "Not in a git repository"
  hook_success
  exit 0
}

# Get relative path from repo root
REL_PATH=$(realpath --relative-to="$REPO_ROOT" "$FILE_PATH" 2>/dev/null) || REL_PATH="$FILE_PATH"

# Check for uncommitted changes (staged or unstaged)
cd "$REPO_ROOT" || {
  json_response "approve" "Could not access repository"
  hook_success
  exit 0
}

# Check both staged and unstaged changes
HAS_STAGED=$(git diff --cached --name-only -- "$REL_PATH" 2>/dev/null | wc -l | tr -d ' ')
HAS_UNSTAGED=$(git diff --name-only -- "$REL_PATH" 2>/dev/null | wc -l | tr -d ' ')

if (( HAS_STAGED > 0 || HAS_UNSTAGED > 0 )); then
  # Build warning message
  CHANGE_TYPE=""
  if (( HAS_STAGED > 0 && HAS_UNSTAGED > 0 )); then
    CHANGE_TYPE="staged AND unstaged"
  elif (( HAS_STAGED > 0 )); then
    CHANGE_TYPE="staged"
  else
    CHANGE_TYPE="unstaged"
  fi

  # Get a summary of the changes
  DIFF_STATS=$(git diff --stat -- "$REL_PATH" 2>/dev/null | tail -1 || echo "")

  # Emit telemetry
  safe_emit "uncommitted_change_warning" "$(jq -n \
    --arg file "$REL_PATH" \
    --arg change_type "$CHANGE_TYPE" \
    '{file: $file, change_type: $change_type}')" 2>/dev/null || true

  # Warn but don't block - the user approved the edit
  json_response "approve" "WARNING: File has $CHANGE_TYPE changes that will be overwritten.
File: $REL_PATH
$DIFF_STATS
Consider: git stash or git add before proceeding."
  hook_success
  exit 0
fi

json_response "approve" "No uncommitted changes"
hook_success
exit 0
