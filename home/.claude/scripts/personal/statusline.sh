#!/bin/bash
exec 2>/dev/null

input=$(cat)
[[ -z "$input" ]] && exit 0

MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
WORKDIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
PERCENT_FREE=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')

[[ "$DURATION_MS" == "null" || -z "$DURATION_MS" ]] && DURATION_MS=0
[[ "$PERCENT_FREE" == "null" || -z "$PERCENT_FREE" ]] && PERCENT_FREE=100

DIRNAME=$(basename "$WORKDIR" 2>/dev/null || echo ".")
BRANCH=$(git -C "$WORKDIR" rev-parse --abbrev-ref HEAD 2>/dev/null)

DURATION_SEC=$((DURATION_MS / 1000))
HOURS=$((DURATION_SEC / 3600))
MINUTES=$(((DURATION_SEC % 3600) / 60))
SECS=$((DURATION_SEC % 60))

if ((HOURS > 0)); then
  DURATION="${HOURS}h${MINUTES}m"
elif ((MINUTES > 0)); then
  DURATION="${MINUTES}m${SECS}s"
else
  DURATION="${SECS}s"
fi

GIT_ICON=$''
FOLDER_ICON=$''
MODEL_ICON=$'󰚩'
CLOCK_ICON=$''
CTX_ICON=$''

C=$'\x1b[36m'  # cyan
G=$'\x1b[32m'  # green
M=$'\x1b[35m'  # magenta
B=$'\x1b[34m'  # blue

if ((PERCENT_FREE > 40)); then
  PC=$G
elif ((PERCENT_FREE > 15)); then
  PC=$'\x1b[33m'
else
  PC=$'\x1b[31m'
fi

GIT_PART=$([[ -n "$BRANCH" ]] && echo "${G}${GIT_ICON} git(${BRANCH}) " || echo "")

printf '%s\n' "${B}${FOLDER_ICON} ${DIRNAME} ${GIT_PART}${C}${MODEL_ICON} ${MODEL} ${M}${CLOCK_ICON} ${DURATION} ${PC}${CTX_ICON} ${PERCENT_FREE}% free"
