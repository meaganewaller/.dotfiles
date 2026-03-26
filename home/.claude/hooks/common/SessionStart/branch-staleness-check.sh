#!/usr/bin/env bash
# SessionStart: Warn if current branch is significantly behind main
# Helps prevent working on stale code that will have merge conflicts
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "branch-staleness-check"
hook_set_context "$INPUT"

# Configurable threshold (commits behind main to trigger warning)
STALENESS_THRESHOLD="${STALENESS_THRESHOLD:-20}"

# Check if we're in a git repo
if ! git rev-parse --git-dir &>/dev/null; then
  hook_success
  exit 0
fi

# Get current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null) || {
  # Detached HEAD state
  hook_success
  exit 0
}

# Skip if we're on main/master
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  hook_success
  exit 0
fi

# Determine the main branch name
MAIN_BRANCH=""
if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
  MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
  MAIN_BRANCH="master"
else
  # No main/master branch found
  hook_success
  exit 0
fi

# Fetch latest from origin (quick timeout, don't block on network issues)
# Use timeout if available, otherwise skip fetch
if command -v timeout &>/dev/null; then
  timeout 5 git fetch origin "$MAIN_BRANCH" --quiet 2>/dev/null || true
elif command -v gtimeout &>/dev/null; then
  gtimeout 5 git fetch origin "$MAIN_BRANCH" --quiet 2>/dev/null || true
fi

# Count commits current branch is behind main
BEHIND_COUNT=$(git rev-list --count "$CURRENT_BRANCH..origin/$MAIN_BRANCH" 2>/dev/null) || BEHIND_COUNT=0
AHEAD_COUNT=$(git rev-list --count "origin/$MAIN_BRANCH..$CURRENT_BRANCH" 2>/dev/null) || AHEAD_COUNT=0

# Check staleness
if (( BEHIND_COUNT >= STALENESS_THRESHOLD )); then
  # Get age of the branch point
  BRANCH_POINT=$(git merge-base "$CURRENT_BRANCH" "origin/$MAIN_BRANCH" 2>/dev/null) || BRANCH_POINT=""
  BRANCH_AGE=""
  if [[ -n "$BRANCH_POINT" ]]; then
    BRANCH_AGE=$(git log -1 --format="%ar" "$BRANCH_POINT" 2>/dev/null) || BRANCH_AGE="unknown"
  fi

  # Emit telemetry
  safe_emit "branch_stale" "$(jq -n \
    --arg branch "$CURRENT_BRANCH" \
    --arg main "$MAIN_BRANCH" \
    --argjson behind "$BEHIND_COUNT" \
    --argjson ahead "$AHEAD_COUNT" \
    '{branch: $branch, main: $main, behind: $behind, ahead: $ahead}')" 2>/dev/null || true

  # Build warning message
  WARNING="Branch '$CURRENT_BRANCH' is $BEHIND_COUNT commits behind $MAIN_BRANCH"
  [[ -n "$BRANCH_AGE" ]] && WARNING="$WARNING (diverged $BRANCH_AGE)"
  WARNING="$WARNING.

Consider:
  git fetch origin $MAIN_BRANCH
  git rebase origin/$MAIN_BRANCH

Or merge: git merge origin/$MAIN_BRANCH"

  # Output as system reminder
  jq -n --arg warning "$WARNING" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("# Branch Staleness Warning\n\n" + $warning)
    }
  }'
fi

hook_success
exit 0
