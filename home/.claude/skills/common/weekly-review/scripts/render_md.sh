#!/usr/bin/env bash
set -euo pipefail

SUMMARY_JSON="${1:-}"
if [[ -z "$SUMMARY_JSON" || ! -f "$SUMMARY_JSON" ]]; then
  echo "Usage: render_md.sh path/to/summary.json" >&2
  exit 1
fi

OUT_DIR="$(cd "$(dirname "$SUMMARY_JSON")" && pwd)"
OUT_MD="$OUT_DIR/review.md"
CHARTS_DIR="$OUT_DIR/charts"

WINDOW_SINCE=$(jq -r '.window.since' "$SUMMARY_JSON")
WINDOW_UNTIL=$(jq -r '.window.until' "$SUMMARY_JSON")

EVENTS_TOTAL=$(jq -r '.counts.events_total' "$SUMMARY_JSON")
WRITES=$(jq -r '.counts.writes' "$SUMMARY_JSON")
FAILURES=$(jq -r '.counts.failures' "$SUMMARY_JSON")
TRADEOFFS=$(jq -r '.counts.tradeoff_events' "$SUMMARY_JSON")
LARGE=$(jq -r '.counts.large_change_events' "$SUMMARY_JSON")
REVERSALS=$(jq -r '.counts.reversal_events' "$SUMMARY_JSON")
DEPS=$(jq -r '.counts.dependency_change_events' "$SUMMARY_JSON")
TESTS_TOTAL=$(jq -r '.counts.test_runs_total' "$SUMMARY_JSON")
TESTS_PASSED=$(jq -r '.counts.test_runs_passed' "$SUMMARY_JSON")
TEST_RATE=$(jq -r '.counts.test_stability_rate' "$SUMMARY_JSON")

{
  echo "# Weekly Engineering Review"
  echo
  echo "**Window:** $WINDOW_SINCE → $WINDOW_UNTIL"
  echo
  echo "## 📊 Execution Summary"
  echo "- Total events: $EVENTS_TOTAL"
  echo "- Writes: $WRITES"
  echo "- Failures/friction: $FAILURES"
  echo "- Tradeoff events: $TRADEOFFS"
  echo "- Large changes: $LARGE"
  echo "- Reversals: $REVERSALS"
  echo "- Dependency changes: $DEPS"
  echo "- Test runs: $TESTS_PASSED / $TESTS_TOTAL passed (rate: $TEST_RATE)"
  echo
  echo "## 🔁 Repeated Friction"
  jq -r '.top_friction_domains[]? | "- \(.domain): \(.count)"' "$SUMMARY_JSON" || true
  echo
  echo "## 🧠 Architectural Thinking"
  jq -r '.top_principles_invoked[]? | "- \(.principle): \(.count)"' "$SUMMARY_JSON" || true
  echo
  echo "## 📈 Charts"
  if [[ -d "$CHARTS_DIR" ]]; then
    [[ -f "$CHARTS_DIR/events_by_type.png" ]] && echo "- events_by_type: $CHARTS_DIR/events_by_type.png"
    [[ -f "$CHARTS_DIR/friction_domains.png" ]] && echo "- friction_domains: $CHARTS_DIR/friction_domains.png"
    [[ -f "$CHARTS_DIR/principles_invoked.png" ]] && echo "- principles_invoked: $CHARTS_DIR/principles_invoked.png"
  else
    echo "_(Charts not generated yet)_"
  fi
  echo
  echo "## 🚀 Promotion-Ready Impact Bullets (Draft)"
  echo "- (Claude will fill this in during /weekly-review)"
  echo
  echo "## 🎯 Precision Moves for Next Week"
  echo "- (Claude will fill this in during /weekly-review)"
} > "$OUT_MD"

echo "✓ Wrote $OUT_MD"
