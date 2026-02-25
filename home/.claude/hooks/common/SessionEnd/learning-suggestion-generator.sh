#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.claude/learning-targets"

IMPACT_LOG="$HOME/.claude/impact-log.jsonl"
FRICTION_LOG="$HOME/.claude/skill-friction-log.jsonl"
JOURNAL_DIR="$HOME/.claude/decision-journal"
OUT="$HOME/.claude/learning-targets/latest.md"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Default counts
impact_count=0
friction_count=0

if [[ -f "$IMPACT_LOG" ]]; then
  impact_count=$(wc -l < "$IMPACT_LOG" | tr -d ' ')
fi

if [[ -f "$FRICTION_LOG" ]]; then
  friction_count=$(wc -l < "$FRICTION_LOG" | tr -d ' ')
fi

# Top friction domains (last 30 entries to keep it fast)
# Note: friction log uses proper JSONL (one object per line)
top_domains=$(
  if [[ -f "$FRICTION_LOG" ]]; then
    tail -n 30 "$FRICTION_LOG" \
      | jq -r '.domain // "unknown"' 2>/dev/null \
      | sort | uniq -c | sort -nr \
      | head -n 5 \
      | awk '{printf "- %s (recent hits: %s)\n", $2, $1}'
  fi
)

# Top skill domains from impact log (last 30 entries)
# Note: impact log may have pretty-printed JSON, use slurp to handle multi-line objects
top_skills=$(
  if [[ -f "$IMPACT_LOG" ]]; then
    jq -rs '.[-30:] | .[] | .skill_domains[]? // empty' "$IMPACT_LOG" 2>/dev/null \
      | sort | uniq -c | sort -nr \
      | head -n 5 \
      | awk '{count=$1; $1=""; sub(/^ +/, ""); printf "- %s (recent touches: %s)\n", $0, count}'
  fi
)

# Decision journal keywords (super light heuristic)
principles=$(
  if [[ -d "$JOURNAL_DIR" ]]; then
    find "$JOURNAL_DIR" -maxdepth 1 -type f -name "*.md" -exec tail -n 200 {} + 2>/dev/null \
      | tr '[:upper:]' '[:lower:]' \
      | grep -oE "idempotent|deterministic|separation of concerns|layering|interface|contract|observability|reliability|performance|simplicity|security" \
      | sort | uniq -c | sort -nr \
      | head -n 6 \
      | awk '{printf "- %s (mentions: %s)\n", $2, $1}'
  fi
)

{
  echo "# Learning Targets (latest)"
  echo
  echo "- Generated: $NOW"
  echo "- Impact entries: $impact_count"
  echo "- Friction entries: $friction_count"
  echo
  echo "## Where you’re bleeding"
  if [[ -n "${top_domains:-}" ]]; then
    echo "$top_domains"
  else
    echo "- (No friction data yet)"
  fi
  echo
  echo "## Where you’re investing"
  if [[ -n "${top_skills:-}" ]]; then
    echo "$top_skills"
  else
    echo "- (No impact data yet)"
  fi
  echo
  echo "## Principles showing up in your decisions"
  if [[ -n "${principles:-}" ]]; then
    echo "$principles"
  else
    echo "- (No decision journal data yet)"
  fi
  echo
  echo "## Next 3 precision moves"
  echo "- Pick the #1 friction domain and do 45 minutes of deliberate practice: reproduce → isolate → fix → write down the rule."
  echo "- For the #1 impact skill domain, read one high-quality reference (official docs / book chapter) and extract 3 rules you will apply next week."
  echo "- Turn one decision principle into a short post: \"Why we chose X over Y\" (with one concrete example)."
} > "$OUT"

exit 0
