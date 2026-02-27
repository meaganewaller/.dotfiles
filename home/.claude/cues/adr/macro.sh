#!/usr/bin/env bash
# Macro for ADR cue - detects project ADR configuration and recent decisions

set -euo pipefail

# Find ADR directory
ADR_DIR=""
for candidate in "docs/architecture/decisions" "docs/adr" "adr" "decisions"; do
  if [[ -d "$candidate" ]]; then
    ADR_DIR="$candidate"
    break
  fi
done

if [[ -z "$ADR_DIR" ]]; then
  echo "**No ADR directory found.** Consider creating \`docs/architecture/decisions/\`"
  exit 0
fi

# Count ADRs by status
total=$(find "$ADR_DIR" -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$total" -eq 0 ]]; then
  echo "**ADR directory exists** at \`$ADR_DIR\` but contains no decisions yet."
  exit 0
fi

# Get the latest ADR (by modification time, excluding README)
latest_name=""
latest_mtime=0
for file in "$ADR_DIR"/*.md; do
  [[ -f "$file" ]] || continue
  name=$(basename "$file")
  [[ "$name" == "README.md" ]] && continue
  mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
  if [[ "$mtime" -gt "$latest_mtime" ]]; then
    latest_mtime="$mtime"
    latest_name="${name%.md}"
  fi
done

# Count by status if we can grep for it
accepted=$(grep -l "^status: accepted" "$ADR_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
proposed=$(grep -l "^status: proposed" "$ADR_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")
superseded=$(grep -l "^status: superseded" "$ADR_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo "**Project ADRs**: $total total in \`$ADR_DIR\`"
if [[ "$proposed" -gt 0 ]]; then
  echo "- $proposed proposed (awaiting decision)"
fi
if [[ "$accepted" -gt 0 ]]; then
  echo "- $accepted accepted"
fi
if [[ "$superseded" -gt 0 ]]; then
  echo "- $superseded superseded"
fi
if [[ -n "$latest_name" ]]; then
  echo "- Latest: \`$latest_name\`"
fi
