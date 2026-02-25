#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/weekly-review/scripts"

# 1. Aggregate
OUT_DIR=$("$SKILL_DIR/aggregate.sh")

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

# 4. Generate markdown
bash "$SKILL_DIR/render_md.sh" "$SUMMARY_JSON"

# 5. Generate dashboard
python3 "$SKILL_DIR/render_dashboard.py" "$SUMMARY_JSON"

echo "✓ Weekly review generated at: $OUT_DIR"
echo "$OUT_DIR"
