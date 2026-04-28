#!/usr/bin/env bash

# This hook is triggered when the user is idle in the prompt.
# It will send a notification to the user that the prompt is idle.

# Get the current time
CURRENT_TIME=$(date +%s)

# Get the last time the user was active
LAST_ACTIVE_TIME=$(cat "$HOME/.claude/last_active_time" 2>/dev/null || echo 0)

# Calculate the time since the last active time
TIME_SINCE_LAST_ACTIVE=$((CURRENT_TIME - LAST_ACTIVE_TIME))

# If the time since the last active time is greater than 10 seconds, send a notification to the user
if ((TIME_SINCE_LAST_ACTIVE > 10)); then
  notify-send "Idle Prompt" "The prompt is idle for $TIME_SINCE_LAST_ACTIVE seconds"
fi

# Update the last active time
echo "$CURRENT_TIME" > "$HOME/.claude/last_active_time"