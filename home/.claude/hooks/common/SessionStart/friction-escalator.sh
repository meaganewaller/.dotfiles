#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.claude/skill-friction-log.jsonl"

if [[ ! -f "$LOG" ]]; then
  exit 0
fi

# Get recent entries (last 20)
RECENT=$(tail -n 20 "$LOG")

# Find most common domain (excluding "unknown")
DOMAIN_STATS=$(echo "$RECENT" | jq -r '.domain' | grep -v "^unknown$" | sort | uniq -c | sort -nr | head -n1)
DOMAIN=$(echo "$DOMAIN_STATS" | awk '{print $2}')
COUNT=$(echo "$DOMAIN_STATS" | awk '{print $1}')

# If no classified domains, check if there are unknowns
if [[ -z "$DOMAIN" || "$DOMAIN" == "" ]]; then
  UNKNOWN_COUNT=$(echo "$RECENT" | jq -r '.domain' | grep -c "^unknown$" || echo "0")
  if (( UNKNOWN_COUNT >= 3 )); then
    jq -n \
      --arg msg "Repeated friction detected in domain: unknown ($UNKNOWN_COUNT recent hits). Consider deliberate study." \
      '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$msg}}'
  fi
  exit 0
fi

# Get subdomain breakdown for the top domain
SUBDOMAIN_BREAKDOWN=$(echo "$RECENT" | jq -r "select(.domain == \"$DOMAIN\") | .subdomain // \"general\"" | sort | uniq -c | sort -nr | head -n3 | awk '{printf "%s(%d) ", $2, $1}')

# Get the most recent hint for this domain
LATEST_HINT=$(echo "$RECENT" | jq -r "select(.domain == \"$DOMAIN\") | .hints[0] // empty" | tail -n1)

if (( COUNT >= 3 )); then
  MSG="Repeated friction in [$DOMAIN]: $COUNT hits. Subdomains: ${SUBDOMAIN_BREAKDOWN:-none}."
  if [[ -n "$LATEST_HINT" ]]; then
    MSG="$MSG Hint: $LATEST_HINT"
  fi

  jq -n \
    --arg msg "$MSG" \
    '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$msg}}'
  exit 0
fi

exit 0
