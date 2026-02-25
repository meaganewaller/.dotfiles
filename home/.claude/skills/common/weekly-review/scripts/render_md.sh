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

# Core metrics
EVENTS_TOTAL=$(jq -r '.counts.events_total' "$SUMMARY_JSON")
PROJECTS=$(jq -r '.counts.projects_touched // 0' "$SUMMARY_JSON")
SESSIONS=$(jq -r '.counts.sessions_total // 0' "$SUMMARY_JSON")
FILES_MOD=$(jq -r '.counts.files_modified // 0' "$SUMMARY_JSON")
WRITES=$(jq -r '.counts.writes' "$SUMMARY_JSON")
FAILURES=$(jq -r '.counts.failures' "$SUMMARY_JSON")
TRADEOFFS=$(jq -r '.counts.tradeoff_events' "$SUMMARY_JSON")
LARGE=$(jq -r '.counts.large_change_events' "$SUMMARY_JSON")
REVERSALS=$(jq -r '.counts.reversal_events' "$SUMMARY_JSON")
DEPS=$(jq -r '.counts.dependency_change_events' "$SUMMARY_JSON")
TESTS_TOTAL=$(jq -r '.counts.test_runs_total' "$SUMMARY_JSON")
TESTS_PASSED=$(jq -r '.counts.test_runs_passed' "$SUMMARY_JSON")
TEST_RATE=$(jq -r '.counts.test_stability_rate' "$SUMMARY_JSON")

# Calculate failure rate
if [[ "$EVENTS_TOTAL" -gt 0 ]]; then
  FAILURE_RATE=$(echo "scale=1; $FAILURES * 100 / $EVENTS_TOTAL" | bc)
else
  FAILURE_RATE="0"
fi

{
  echo "# Weekly Engineering Review"
  echo
  echo "**Window:** $WINDOW_SINCE → $WINDOW_UNTIL"
  echo
  echo "## 📝 Executive Summary"
  echo
  echo "<!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->"
  echo "_Claude will synthesize execution quality, risk, and discipline here._"
  echo "<!-- END:EXECUTIVE_SUMMARY -->"
  echo
  echo "## 📊 Execution Metrics"
  echo
  echo "### Overview"
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Projects touched | $PROJECTS |"
  echo "| Sessions | $SESSIONS |"
  echo "| Total events | $EVENTS_TOTAL |"
  echo "| Files modified | $FILES_MOD |"
  echo "| Writes | $WRITES |"
  echo "| Failures/friction | $FAILURES ($FAILURE_RATE%) |"
  echo "| Tradeoff events | $TRADEOFFS |"
  echo "| Large changes | $LARGE |"
  echo "| Reversals | $REVERSALS |"
  echo "| Dependency changes | $DEPS |"
  echo "| Test runs | $TESTS_PASSED / $TESTS_TOTAL passed (rate: $TEST_RATE) |"
  echo
  echo "### Per-Project Breakdown"
  echo "| Project | Events | Sessions | Writes | Failures | Tradeoffs |"
  echo "|---------|--------|----------|--------|----------|-----------|"
  jq -r '.projects[]? | "| \(.project) | \(.events) | \(.sessions) | \(.writes) | \(.failures) | \(.tradeoffs) |"' "$SUMMARY_JSON" || echo "_(No project data)_"
  echo
  echo "## 🔁 Repeated Friction"
  echo
  echo "### By Domain"
  jq -r '.top_friction_domains[]? | "- **\(.domain)**: \(.count)"' "$SUMMARY_JSON" || echo "_(No friction data)_"
  echo
  echo "### By Subdomain"
  jq -r '.top_friction_subdomains[]? | "- \(.subdomain): \(.count)"' "$SUMMARY_JSON" || echo "_(No subdomain data)_"
  echo
  echo "### Analysis"
  echo
  echo "<!-- PLACEHOLDER:FRICTION_ANALYSIS -->"
  echo "_Claude will analyze top friction domains and propose deliberate practice here._"
  echo "<!-- END:FRICTION_ANALYSIS -->"
  echo
  echo "## 🧠 Architectural Thinking"
  echo
  echo "### Principles Invoked"
  jq -r '.top_principles_invoked[]? | "- \(.principle): \(.count)"' "$SUMMARY_JSON" || echo "_(No principles data)_"
  echo
  echo "### Skills Demonstrated"
  jq -r '.top_skills_used[]? | "- \(.skill): \(.count)"' "$SUMMARY_JSON" || echo "_(No skills data)_"
  echo
  echo "### Analysis"
  echo
  echo "<!-- PLACEHOLDER:ARCHITECTURE_ANALYSIS -->"
  echo "_Claude will interpret dominant principles, strengths, and blindspots here._"
  echo "<!-- END:ARCHITECTURE_ANALYSIS -->"
  echo
  echo "## ⚠️ Discipline Flags"
  echo
  echo "<!-- PLACEHOLDER:DISCIPLINE_FLAGS -->"
  echo "_Claude will flag large-change-without-tradeoff, reversals, dependency churn here._"
  echo "<!-- END:DISCIPLINE_FLAGS -->"
  echo
  echo "## 📁 Files Modified"
  echo
  jq -r '.top_files_modified[]? | "- `\(.)`"' "$SUMMARY_JSON" | head -15 || echo "_(No files data)_"
  echo
  echo "## 📈 Charts"
  if [[ -d "$CHARTS_DIR" ]]; then
    [[ -f "$CHARTS_DIR/events_by_type.png" ]] && echo "![Events by Type]($CHARTS_DIR/events_by_type.png)"
    [[ -f "$CHARTS_DIR/friction_domains.png" ]] && echo "![Friction Domains]($CHARTS_DIR/friction_domains.png)"
    [[ -f "$CHARTS_DIR/principles_invoked.png" ]] && echo "![Principles Invoked]($CHARTS_DIR/principles_invoked.png)"
  else
    echo "_(Charts not generated - matplotlib not installed)_"
  fi
  echo
  echo "## 🚀 Promotion-Ready Impact Bullets"
  echo
  echo "<!-- PLACEHOLDER:IMPACT_BULLETS -->"
  echo "_Claude will generate 4-6 specific, measurable bullets grounded in patterns._"
  echo "<!-- END:IMPACT_BULLETS -->"
  echo
  echo "## 🎯 Precision Moves for Next Week"
  echo
  echo "<!-- PLACEHOLDER:PRECISION_MOVES -->"
  echo "_Claude will provide exactly 3 moves: 1 architecture, 1 skill deepening, 1 leverage._"
  echo "<!-- END:PRECISION_MOVES -->"
} > "$OUT_MD"

echo "✓ Wrote $OUT_MD"
