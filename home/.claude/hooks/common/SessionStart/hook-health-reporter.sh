#!/usr/bin/env bash
set -euo pipefail

# Hook Health Reporter - Surfaces hook failures at session start
# This provides "observability of the observer" - monitoring the monitoring system.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Don't monitor ourselves
# hook_register "hook-health-reporter"

HEALTH_LOG="$CLAUDE_HOOK_HEALTH_LOG"

if [[ ! -f "$HEALTH_LOG" ]]; then
  exit 0
fi

# Get failures in the last 24 hours
SUMMARY=$(hook_health_summary 24)

if [[ -z "$SUMMARY" || "$SUMMARY" == "[]" || "$SUMMARY" == "{}" ]]; then
  exit 0
fi

# Count total failures
TOTAL_FAILURES=$(echo "$SUMMARY" | jq '[.[].failure] | add // 0')
TOTAL_RUNS=$(echo "$SUMMARY" | jq '[.[].total] | add // 0')

# Only report if there are failures
if [[ "$TOTAL_FAILURES" -eq 0 ]]; then
  exit 0
fi

# Calculate failure rate
if [[ "$TOTAL_RUNS" -gt 0 ]]; then
  FAILURE_RATE=$(echo "scale=1; $TOTAL_FAILURES * 100 / $TOTAL_RUNS" | bc)
else
  FAILURE_RATE="0"
fi

# Get hooks with failures, sorted by failure count
FAILING_HOOKS=$(echo "$SUMMARY" | jq -r '
  map(select(.failure > 0))
  | sort_by(-.failure)
  | .[:3]
  | map("\(.hook): \(.failure)/\(.total) failed" + (if .last_error then " (\(.last_error))" else "" end))
  | join("; ")
')

# Build message
MSG="Hook health (24h): $TOTAL_FAILURES failures across $TOTAL_RUNS runs (${FAILURE_RATE}% failure rate)."
if [[ -n "$FAILING_HOOKS" ]]; then
  MSG="$MSG Top issues: $FAILING_HOOKS"
fi

# Only surface if failure rate is concerning (>10%) or many failures (>5)
if (( $(echo "$FAILURE_RATE > 10" | bc -l) )) || (( TOTAL_FAILURES > 5 )); then
  jq -n \
    --arg msg "$MSG" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$msg}}'
fi

exit 0
