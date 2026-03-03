#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
COMMAND=$(jq -r '.tool_input.command // ""' <<<"$INPUT")

json() {
  jq -n --arg decision "$1" --arg reason "$2" '{decision:$decision,reason:$reason}'
}

if [[ "$TOOL" != "Bash" ]]; then
  json approve "Not a Bash command"
  exit 0
fi

# ============================================================
# 1. DANGEROUS COMMAND BLOCKER
# ============================================================

declare -a PATTERNS=(
'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*/([[:space:]]|$|\*)::rm on root directory'
'rm[[:space:]]+-[a-zA-Z]*rf\b::recursive force delete'
'mkfs\.::filesystem format'
'dd[[:space:]]+.*of=/dev/::raw disk write'
':\(\)[[:space:]]*\{[[:space:]]*:\|:[[:space:]]*&[[:space:]]*\}[[:space:]]*;:::fork bomb'
'>[[:space:]]*/dev/sd[a-z]::raw device write'
'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/::recursive 777 on root'
'DROP[[:space:]]+DATABASE::drop database'
'DROP[[:space:]]+TABLE::drop table'
'TRUNCATE[[:space:]]+TABLE::truncate table'
'DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z0-9_]+[[:space:]]*;?[[:space:]]*$::delete all rows (no WHERE)'
)

for entry in "${PATTERNS[@]}"; do
  PATTERN=${entry%%::*}
  DESC=${entry##*::}

  if grep -Eqi "$PATTERN" <<<"$COMMAND"; then
    SHORT=${COMMAND:0:100}
    json block "BLOCKED: Dangerous command detected — $DESC
Command: $SHORT"
    exit 0
  fi
done


# ============================================================
# 2. CONVENTIONAL COMMITS ENFORCER
# ============================================================

if grep -Eq 'git[[:space:]]+commit\b' <<<"$COMMAND" && ! [[ "$COMMAND" =~ ^# ]]; then

  MSG=$(grep -oE '-m[[:space:]]+["'\''][^"'\'']+["'\'']' <<<"$COMMAND" | sed 's/-m[[:space:]]*["'\'']//;s/["'\'']$//' || true)

  if [[ -z "$MSG" ]]; then
    MSG=$(awk '/<<.*EOF/{capture=1;next} capture && NF{print;exit}' <<<"$COMMAND" || true)
  fi

  if [[ -n "$MSG" ]]; then
    TYPES="feat|fix|refactor|docs|test|chore|perf|ci|style|build|revert"

    if ! [[ "$MSG" =~ ^($TYPES)(\(.+\))?!?:[[:space:]]+.+ ]]; then
      SHORT=${MSG:0:80}
      json block "Commit message does not follow conventional format.
Expected: <type>: <description>
Types: feat, fix, refactor, docs, test, chore, perf, ci, style, build, revert
Got: $SHORT"
      exit 0
    fi
  fi
fi

# ============================================================
# ALL CLEAR
# ============================================================

json approve "Command approved"
