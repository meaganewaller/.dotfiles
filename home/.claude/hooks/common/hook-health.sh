#!/usr/bin/env bash
set -euo pipefail

# Hook Health CLI - Check the health of your Claude hooks
# Usage:
#   hook-health.sh          # Show 24h summary
#   hook-health.sh 168      # Show 7-day summary (168 hours)
#   hook-health.sh --recent # Show last 10 executions
#   hook-health.sh --tail   # Follow health log in real-time

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

HEALTH_LOG="$CLAUDE_HOOK_HEALTH_LOG"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
  cat << 'EOF'
Hook Health CLI - Monitor Claude hook execution

Usage:
  hook-health.sh [OPTIONS] [HOURS]

Options:
  --recent, -r    Show last 10 hook executions
  --tail, -t      Follow health log in real-time
  --failures, -f  Show only failures
  --help, -h      Show this help

Arguments:
  HOURS           Time window in hours (default: 24)

Examples:
  hook-health.sh          # 24-hour summary
  hook-health.sh 168      # 7-day summary
  hook-health.sh -r       # Recent executions
  hook-health.sh -f       # Recent failures only
EOF
}

show_summary() {
  local hours="${1:-24}"

  if [[ ! -f "$HEALTH_LOG" ]]; then
    echo -e "${YELLOW}No hook health data yet.${NC}"
    echo "Health log will be created as hooks run."
    exit 0
  fi

  local summary
  summary=$(hook_health_summary "$hours")

  if [[ -z "$summary" || "$summary" == "[]" ]]; then
    echo -e "${GREEN}No hook executions in the last ${hours}h.${NC}"
    exit 0
  fi

  local total_runs total_failures total_success
  total_runs=$(echo "$summary" | jq '[.[].total] | add // 0')
  total_failures=$(echo "$summary" | jq '[.[].failure] | add // 0')
  total_success=$(echo "$summary" | jq '[.[].success] | add // 0')

  echo -e "${BLUE}=== Hook Health Report (${hours}h) ===${NC}"
  echo

  # Overall stats
  if [[ "$total_failures" -eq 0 ]]; then
    echo -e "${GREEN}✓ All hooks healthy${NC} - $total_success successful executions"
  else
    local rate
    rate=$(echo "scale=1; $total_failures * 100 / $total_runs" | bc)
    echo -e "${RED}⚠ $total_failures failures${NC} out of $total_runs executions (${rate}% failure rate)"
  fi
  echo

  # Per-hook breakdown
  echo -e "${BLUE}Per-Hook Breakdown:${NC}"
  echo "$summary" | jq -r '.[] |
    if .failure > 0 then
      "  \u001b[31m✗\u001b[0m \(.hook): \(.success)/\(.total) ok, \(.failure) failed (\(.avg_duration_ms)ms avg)"
    else
      "  \u001b[32m✓\u001b[0m \(.hook): \(.total) ok (\(.avg_duration_ms)ms avg)"
    end'
  echo

  # Show recent errors if any
  if [[ "$total_failures" -gt 0 ]]; then
    echo -e "${BLUE}Recent Errors:${NC}"
    echo "$summary" | jq -r '.[] | select(.last_error != null) | "  \(.hook): \(.last_error)"'
  fi
}

show_recent() {
  local count="${1:-10}"

  if [[ ! -f "$HEALTH_LOG" ]]; then
    echo -e "${YELLOW}No hook health data yet.${NC}"
    exit 0
  fi

  echo -e "${BLUE}=== Last $count Hook Executions ===${NC}"
  echo

  tail -n "$count" "$HEALTH_LOG" | jq -r '
    if .status == "success" then
      "\u001b[32m✓\u001b[0m \(.timestamp | split("T")[1] | split("Z")[0]) \(.hook) (\(.duration_ms)ms)"
    else
      "\u001b[31m✗\u001b[0m \(.timestamp | split("T")[1] | split("Z")[0]) \(.hook) - \(.error // "unknown error")"
    end'
}

show_failures() {
  local count="${1:-20}"

  if [[ ! -f "$HEALTH_LOG" ]]; then
    echo -e "${YELLOW}No hook health data yet.${NC}"
    exit 0
  fi

  echo -e "${BLUE}=== Recent Hook Failures ===${NC}"
  echo

  grep '"status":"failure"' "$HEALTH_LOG" 2>/dev/null | tail -n "$count" | jq -r '
    "\u001b[31m✗\u001b[0m \(.timestamp) \(.hook): \(.error // "unknown error")"
  ' || echo -e "${GREEN}No failures found.${NC}"
}

follow_log() {
  if [[ ! -f "$HEALTH_LOG" ]]; then
    echo -e "${YELLOW}Waiting for hook health data...${NC}"
    touch "$HEALTH_LOG"
  fi

  echo -e "${BLUE}Following hook health log (Ctrl+C to stop)...${NC}"
  echo

  tail -f "$HEALTH_LOG" | jq -r '
    if .status == "success" then
      "\u001b[32m✓\u001b[0m \(.timestamp | split("T")[1] | split("Z")[0]) \(.hook) (\(.duration_ms)ms)"
    else
      "\u001b[31m✗\u001b[0m \(.timestamp | split("T")[1] | split("Z")[0]) \(.hook) - \(.error // "unknown error")"
    end'
}

# Parse arguments
case "${1:-}" in
  --help|-h)
    show_help
    ;;
  --recent|-r)
    show_recent "${2:-10}"
    ;;
  --tail|-t)
    follow_log
    ;;
  --failures|-f)
    show_failures "${2:-20}"
    ;;
  *)
    show_summary "${1:-24}"
    ;;
esac
