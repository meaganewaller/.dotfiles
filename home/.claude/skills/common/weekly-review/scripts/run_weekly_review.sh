#!/usr/bin/env bash
set -euo pipefail

# Generate weekly review artifacts (local only)
# Jekyll publishing happens separately via publish_to_jekyll.sh after AI synthesis
# Usage: run_weekly_review.sh [WEEK_OFFSET]
#   WEEK_OFFSET: 0 = current week (default), -1 = last week, -2 = two weeks ago, etc.

SKILL_DIR="$HOME/.claude/skills/weekly-review/scripts"
WEEK_OFFSET="${1:-0}"

# 1. Aggregate events and publish initial summary to Jekyll
OUT_DIR=$("$SKILL_DIR/aggregate.sh" "$WEEK_OFFSET")

# 2. Determine summary.json path
SUMMARY_JSON="$OUT_DIR/summary.json"

if [[ ! -f "$SUMMARY_JSON" ]]; then
  echo "Missing summary.json" >&2
  exit 1
fi

# 3. Generate charts (optional - requires matplotlib)
if python3 -c "import matplotlib" 2>/dev/null; then
  python3 "$SKILL_DIR/charts.py" "$SUMMARY_JSON"
else
  echo "⚠ Skipping charts (matplotlib not installed)" >&2
fi

# 4. Generate markdown (with placeholders for AI synthesis)
bash "$SKILL_DIR/render_md.sh" "$SUMMARY_JSON"

# 5. Generate dashboard
python3 "$SKILL_DIR/render_dashboard.py" "$SUMMARY_JSON"

echo "✓ Weekly review generated at: $OUT_DIR" >&2
echo "→ Next: AI will fill placeholders, then run publish_to_jekyll.sh" >&2
echo "$OUT_DIR"
