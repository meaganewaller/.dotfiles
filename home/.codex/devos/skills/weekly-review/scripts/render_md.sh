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

# Week info (new schema)
WEEK_START=$(jq -r '.week.start // .window.since // "unknown"' "$SUMMARY_JSON")
WEEK_END=$(jq -r '.week.end // .window.until // "unknown"' "$SUMMARY_JSON")

# Core metrics (support both old and new schema)
EVENTS_TOTAL=$(jq -r '.totals.events // .counts.events_total // 0' "$SUMMARY_JSON")
PROJECTS=$(jq -r '.totals.projects_touched // .counts.projects_touched // 0' "$SUMMARY_JSON")
SESSIONS=$(jq -r '.totals.sessions // .counts.sessions_total // 0' "$SUMMARY_JSON")
WRITES=$(jq -r '.totals.writes // .counts.writes // 0' "$SUMMARY_JSON")
FAILURES=$(jq -r '.totals.failures // .counts.failures // 0' "$SUMMARY_JSON")
TRADEOFFS=$(jq -r '.totals.decisions_documented // .counts.tradeoff_events // 0' "$SUMMARY_JSON")
LARGE=$(jq -r '.totals.large_changes // .counts.large_change_events // 0' "$SUMMARY_JSON")
REVERSALS=$(jq -r '.totals.reversals // .counts.reversal_events // 0' "$SUMMARY_JSON")
DEPS=$(jq -r '.totals.dependency_changes // .counts.dependency_change_events // 0' "$SUMMARY_JSON")
FAILURE_RATE=$(jq -r '.derived_metrics.failure_rate // 0' "$SUMMARY_JSON")

# ADR-0009: Stable session metrics (primary) with fallback to raw metrics
STABLE_SESSION_RATE=$(jq -r '.derived_metrics.test_stability.stable_session_rate // .derived_metrics.test_stability_rate // "N/A"' "$SUMMARY_JSON")
STABLE_SESSION_RUNS=$(jq -r '.derived_metrics.test_stability.stable_session_runs // 0' "$SUMMARY_JSON")
STABLE_SESSION_PASSED=$(jq -r '.derived_metrics.test_stability.stable_session_passed // 0' "$SUMMARY_JSON")
RAW_TEST_RATE=$(jq -r '.derived_metrics.test_stability.raw_rate // .derived_metrics.test_stability_rate // "N/A"' "$SUMMARY_JSON")
RAW_TEST_PASSED=$(jq -r '.derived_metrics.test_stability.raw_passed // .derived_metrics.test_runs_passed // 0' "$SUMMARY_JSON")
RAW_TEST_RUNS=$(jq -r '.derived_metrics.test_stability.raw_runs // .totals.test_runs // 0' "$SUMMARY_JSON")
SQLITE_ERRORS=$(jq -r '.derived_metrics.test_stability.sqlite_environmental_errors // 0' "$SUMMARY_JSON")
STABLE_SESSIONS=$(jq -r '.derived_metrics.test_stability.session_patterns.stable // 0' "$SUMMARY_JSON")
DEV_ITERATION_SESSIONS=$(jq -r '.derived_metrics.test_stability.session_patterns.dev_iteration // 0' "$SUMMARY_JSON")
MIXED_SESSIONS=$(jq -r '.derived_metrics.test_stability.session_patterns.mixed // 0' "$SUMMARY_JSON")

# Format failure rate as percentage
if [[ "$FAILURE_RATE" != "null" && "$FAILURE_RATE" != "N/A" ]]; then
  FAILURE_PCT=$(echo "scale=1; $FAILURE_RATE * 100" | bc 2>/dev/null || echo "0")
else
  FAILURE_PCT="0"
fi

# Format test rates as percentages (one decimal place)
if [[ "$STABLE_SESSION_RATE" != "null" && "$STABLE_SESSION_RATE" != "N/A" ]]; then
  STABLE_TEST_PCT=$(printf "%.1f" "$(echo "$STABLE_SESSION_RATE * 100" | bc)" 2>/dev/null || echo "N/A")
else
  STABLE_TEST_PCT="N/A"
fi

if [[ "$RAW_TEST_RATE" != "null" && "$RAW_TEST_RATE" != "N/A" ]]; then
  RAW_TEST_PCT=$(printf "%.1f" "$(echo "$RAW_TEST_RATE * 100" | bc)" 2>/dev/null || echo "N/A")
else
  RAW_TEST_PCT="N/A"
fi

{
  echo "# Weekly Engineering Review"
  echo
  echo "**Window:** $WEEK_START → $WEEK_END"
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
  echo
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Projects touched | $PROJECTS |"
  echo "| Sessions | $SESSIONS |"
  echo "| Total events | $EVENTS_TOTAL |"
  echo "| Writes | $WRITES |"
  echo "| Failures/friction | $FAILURES ($FAILURE_PCT%) |"
  echo "| Decisions documented | $TRADEOFFS |"
  echo "| Large changes | $LARGE |"
  echo "| Reversals | $REVERSALS |"
  echo "| Dependency changes | $DEPS |"
  echo
  echo "### Test Stability (ADR-0009)"
  echo
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| **Stable session stability** | $STABLE_SESSION_PASSED / $STABLE_SESSION_RUNS ($STABLE_TEST_PCT%) |"
  echo "| Raw stability (all runs) | $RAW_TEST_PASSED / $RAW_TEST_RUNS ($RAW_TEST_PCT%) |"
  echo "| SQLite environmental errors | $SQLITE_ERRORS |"
  echo "| Session patterns | stable: $STABLE_SESSIONS, dev-iteration: $DEV_ITERATION_SESSIONS, mixed: $MIXED_SESSIONS |"
  echo
  echo "> **Note:** Stable session stability excludes expected dev-iteration failures (TDD cycle)."
  echo "> See [ADR-0009](../architecture/0009-test-stability-analysis.md) for methodology."
  echo
  echo "### Per-Project Breakdown"
  echo
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
  echo "## 🎯 Cue Engagement"
  echo
  CUE_TOTAL=$(jq -r '.cue_engagement.total_fires // 0' "$SUMMARY_JSON")
  CUE_UNIQUE=$(jq -r '.cue_engagement.unique_cues_fired // 0' "$SUMMARY_JSON")
  echo "**Total fires:** $CUE_TOTAL | **Unique cues:** $CUE_UNIQUE"
  echo
  echo "### By Cue"
  jq -r '.cue_engagement.by_cue[]? | "- **\(.cue)**: \(.count)"' "$SUMMARY_JSON" || echo "_(No cue data)_"
  echo
  echo "### By Trigger Type"
  jq -r '.cue_engagement.by_trigger[]? | "- \(.trigger): \(.count)"' "$SUMMARY_JSON" || echo "_(No trigger data)_"
  echo
  echo "### Analysis"
  echo
  echo "<!-- PLACEHOLDER:CUE_ENGAGEMENT -->"
  echo "_Claude will analyze cue effectiveness, dormant cues, and trigger patterns here._"
  echo "<!-- END:CUE_ENGAGEMENT -->"
  echo
  echo "## 📈 Charts"
  if [[ -d "$CHARTS_DIR" ]]; then
    [[ -f "$CHARTS_DIR/events_by_type.png" ]] && echo "![Events by Type](/assets/charts/$WEEK_START/events_by_type.png)"
    [[ -f "$CHARTS_DIR/friction_domains.png" ]] && echo "![Friction Domains](/assets/charts/$WEEK_START/friction_domains.png)"
    [[ -f "$CHARTS_DIR/principles_invoked.png" ]] && echo "![Principles Invoked](/assets/charts/$WEEK_START/principles_invoked.png)"
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
