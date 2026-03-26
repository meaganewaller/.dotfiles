#!/usr/bin/env bash
# PreToolUse: Track Agent tool invocations
# Logs agent spawns and warns on excessive parallelism
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "agent-spawn-tracker"
hook_set_context "$INPUT"

TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")

json_response() {
  jq -n --arg decision "$1" --arg reason "$2" '{decision:$decision,reason:$reason}'
}

# Only track Agent tool
if [[ "$TOOL" != "Agent" ]]; then
  json_response "approve" "Not an Agent tool"
  hook_success
  exit 0
fi

# Extract agent parameters
SUBAGENT_TYPE=$(jq -r '.tool_input.subagent_type // "general-purpose"' <<<"$INPUT")
DESCRIPTION=$(jq -r '.tool_input.description // ""' <<<"$INPUT")
RUN_IN_BACKGROUND=$(jq -r '.tool_input.run_in_background // false' <<<"$INPUT")
ISOLATION=$(jq -r '.tool_input.isolation // "none"' <<<"$INPUT")
MODEL=$(jq -r '.tool_input.model // "default"' <<<"$INPUT")

# Track agent spawns in a state file
STATE_FILE="${TEMP:-/tmp}/claude-agent-spawns.json"
LOCKFILE="$STATE_FILE.lock"

# Use flock for exclusive access
exec 200>"$LOCKFILE"
flock -w 5 200 || {
  json_response "approve" "Could not acquire lock"
  hook_success
  exit 0
}

# Load or initialize state
if [[ -f "$STATE_FILE" ]]; then
  STATE=$(jq '.' "$STATE_FILE" 2>/dev/null) || STATE='{}'
else
  STATE='{}'
fi

# Get session ID for tracking
SESSION_ID=$(jq -r '.session_id // "unknown"' <<<"$INPUT")

# Initialize session tracking if needed
STATE=$(jq --arg sid "$SESSION_ID" '
  if .sessions[$sid] == null then
    .sessions[$sid] = {
      spawns: 0,
      background_spawns: 0,
      types: {},
      first_spawn: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
      last_spawn: null
    }
  else .
  end
' <<<"$STATE")

# Update spawn count
STATE=$(jq --arg sid "$SESSION_ID" --arg type "$SUBAGENT_TYPE" --argjson bg "$RUN_IN_BACKGROUND" '
  .sessions[$sid].spawns += 1
  | .sessions[$sid].last_spawn = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
  | .sessions[$sid].types[$type] = ((.sessions[$sid].types[$type] // 0) + 1)
  | if $bg then .sessions[$sid].background_spawns += 1 else . end
' <<<"$STATE")

# Save state
echo "$STATE" > "$STATE_FILE"

# Release lock
flock -u 200

# Get current session stats
SPAWN_COUNT=$(jq -r --arg sid "$SESSION_ID" '.sessions[$sid].spawns' <<<"$STATE")
BG_SPAWN_COUNT=$(jq -r --arg sid "$SESSION_ID" '.sessions[$sid].background_spawns' <<<"$STATE")

# Emit telemetry
safe_emit "agent_spawn" "$(jq -n \
  --arg type "$SUBAGENT_TYPE" \
  --arg desc "$DESCRIPTION" \
  --argjson bg "$RUN_IN_BACKGROUND" \
  --arg isolation "$ISOLATION" \
  --arg model "$MODEL" \
  --argjson spawn_num "$SPAWN_COUNT" \
  '{
    subagent_type: $type,
    description: $desc,
    run_in_background: $bg,
    isolation: $isolation,
    model: $model,
    session_spawn_number: $spawn_num
  }')" 2>/dev/null || true

# Warn on potential issues
WARNING=""

# High spawn count warning
if (( SPAWN_COUNT > 10 )); then
  WARNING="Note: $SPAWN_COUNT agents spawned this session. Consider if tasks could be consolidated."
fi

# Many background agents warning (cumulative this session)
if (( BG_SPAWN_COUNT > 5 )); then
  WARNING="${WARNING:+$WARNING\n}Note: $BG_SPAWN_COUNT background agents spawned this session. Consider tracking completion."
fi

# Worktree isolation note (informational)
if [[ "$ISOLATION" == "worktree" ]]; then
  WARNING="${WARNING:+$WARNING\n}Info: Agent using worktree isolation - changes will be in separate branch."
fi

if [[ -n "$WARNING" ]]; then
  json_response "approve" "$WARNING"
else
  json_response "approve" "Agent spawn tracked (#$SPAWN_COUNT: $SUBAGENT_TYPE)"
fi

hook_success
exit 0
