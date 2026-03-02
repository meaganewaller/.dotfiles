#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

OUT_DIR_BASE="$HOME/.claude/reviews"
PROJECTS_DIR="$HOME/.claude/projects"
GLOBAL_STREAM="$HOME/.claude/dev-os-events.jsonl"
JEKYLL_ROOT="${JEKYLL_ROOT:-$HOME/github/meaganewaller/weekly-reviews}"

# ============================================================================
# Validation
# ============================================================================

# FR-6: Require global stream
if [[ ! -f "$GLOBAL_STREAM" ]]; then
  echo "Error: Missing $GLOBAL_STREAM" >&2
  exit 1
fi

# FR-6: Require Jekyll root directory
if [[ ! -d "$JEKYLL_ROOT" ]]; then
  echo "Error: Jekyll root directory does not exist: $JEKYLL_ROOT" >&2
  exit 1
fi

# ============================================================================
# Setup directories
# ============================================================================

mkdir -p "$OUT_DIR_BASE"

REVIEWS_DIR="$JEKYLL_ROOT/_reviews"
DATA_DIR="$JEKYLL_ROOT/_data/dev_os"

mkdir -p "$REVIEWS_DIR"
mkdir -p "$DATA_DIR"

# ============================================================================
# Compute week boundaries (Monday-based, UTC)
# ============================================================================

read -r WEEK_START WEEK_END < <(python3 - <<'PY'
import datetime as dt
now = dt.datetime.now(dt.timezone.utc)
monday = now - dt.timedelta(days=now.weekday())
monday = dt.datetime(monday.year, monday.month, monday.day, tzinfo=dt.timezone.utc)
sunday = monday + dt.timedelta(days=6)
print(monday.date().isoformat(), sunday.date().isoformat())
PY
)

OUT_DIR="$OUT_DIR_BASE/week-of-$WEEK_START"
mkdir -p "$OUT_DIR"

SUMMARY_JSON="$OUT_DIR/summary.json"

# ============================================================================
# Aggregate events (Python)
# ============================================================================

python3 - <<PY "$GLOBAL_STREAM" "$PROJECTS_DIR" "$SUMMARY_JSON" "$WEEK_START" "$WEEK_END"
import json, sys, datetime as dt
from collections import Counter, defaultdict
from pathlib import Path

stream_path = sys.argv[1]
projects_dir = sys.argv[2]
out_path = sys.argv[3]
week_start = sys.argv[4]
week_end = sys.argv[5]

SCHEMA_VERSION = "1.0.0"

def parse_ts(s: str):
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    return dt.datetime.fromisoformat(s)

def decode_project_name(encoded: str) -> str:
    """Convert -Users-foo-bar to /Users/foo/bar"""
    if encoded.startswith("-"):
        return encoded.replace("-", "/", 1).replace("-", "/")
    return encoded

def build_session_project_map(projects_dir: str) -> dict:
    """Map session_id -> project_name by scanning project directories"""
    session_map = {}
    projects_path = Path(projects_dir)
    if not projects_path.exists():
        return session_map

    for project_dir in projects_path.iterdir():
        if not project_dir.is_dir() or project_dir.name.startswith("."):
            continue
        project_name = decode_project_name(project_dir.name)
        for item in project_dir.iterdir():
            if item.suffix == ".jsonl" and item.is_file():
                session_id = item.stem
                session_map[session_id] = {
                    "project_path": project_name,
                    "project_dir": project_dir.name,
                    "project_short": project_name.split("/")[-1] if "/" in project_name else project_name
                }
    return session_map

now = dt.datetime.now(dt.timezone.utc)
since = now - dt.timedelta(days=7)

session_map = build_session_project_map(projects_dir)

# Read and filter events
events = []
with open(stream_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except Exception:
            continue
        ts = e.get("timestamp")
        if not ts:
            continue
        try:
            t = parse_ts(ts).astimezone(dt.timezone.utc)
        except Exception:
            continue
        if t >= since:
            session_id = e.get("session_id", "")
            event_type = e.get("event_type", "")
            # Skip test sessions and events without valid session IDs
            # But allow decision_tradeoff events (can come from CLI without session)
            if event_type != "decision_tradeoff":
                if not session_id or session_id == "unknown" or session_id.startswith("test"):
                    continue
            if session_id in session_map:
                e["_project"] = session_map[session_id]
            else:
                e["_project"] = {"project_short": "unknown", "project_path": "unknown"}
            events.append(e)

by_type = Counter(e.get("event_type", "unknown") for e in events)

# Per-project aggregations
project_stats = defaultdict(lambda: {
    "events": 0, "writes": 0, "failures": 0, "tradeoffs": 0,
    "large_change_files": set(), "reversals": 0, "sessions": set()
})

# Global aggregations
friction_domains = Counter()
friction_subdomains = Counter()
principles = Counter()
test_results = Counter()
large_change_files = set()  # Track unique files, not event count
reversals = 0
dependency_changes = 0
writes = 0
failures = 0
tradeoffs = 0
files_modified = set()
skills_used = Counter()
cues_fired = Counter()
cue_triggers = Counter()
session_durations = []  # List of (session_id, project, duration_minutes, category)
duration_categories = Counter()
skills_invoked = Counter()  # Track skill usage
context_compacts = []  # Track compaction events

for e in events:
    et = e.get("event_type")
    payload = e.get("payload") or {}
    project = e.get("_project", {}).get("project_short", "unknown")
    session_id = e.get("session_id", "")

    project_stats[project]["events"] += 1
    project_stats[project]["sessions"].add(session_id)

    if et == "tool_write":
        writes += 1
        project_stats[project]["writes"] += 1
        f = payload.get("file")
        if f:
            files_modified.add(f)
        for skill in payload.get("skills") or []:
            if isinstance(skill, str):
                skills_used[skill] += 1

    if et in ("tool_failure", "friction_event"):
        failures += 1
        project_stats[project]["failures"] += 1
        d = payload.get("domain")
        if isinstance(d, str) and d.strip():
            friction_domains[d.strip()] += 1
        fd = payload.get("friction_domain") or {}
        subdomain = fd.get("subdomain")
        if subdomain:
            friction_subdomains[f"{d}:{subdomain}"] += 1

    if et == "decision_tradeoff":
        tradeoffs += 1
        project_stats[project]["tradeoffs"] += 1
        for p in payload.get("principles_invoked") or []:
            if isinstance(p, str) and p.strip():
                principles[p.strip()] += 1

    if et == "test_run":
        r = (payload.get("result") or "").strip().lower()
        if r:
            test_results[r] += 1
        # Aggregate detailed counts if available
        passed_count = payload.get("passed", 0)
        failed_count = payload.get("failed", 0)
        skipped_count = payload.get("skipped", 0)
        test_results["_passed_count"] = test_results.get("_passed_count", 0) + passed_count
        test_results["_failed_count"] = test_results.get("_failed_count", 0) + failed_count
        test_results["_skipped_count"] = test_results.get("_skipped_count", 0) + skipped_count

    if et == "large_change":
        f = payload.get("file_path", "")
        if f:
            large_change_files.add(f)
            project_stats[project]["large_change_files"].add(f)

    if et == "reversal":
        reversals += 1
        project_stats[project]["reversals"] += 1

    if et == "dependency_change":
        dependency_changes += 1

    if et == "cue_fired":
        cue_id = payload.get("cue_id", "unknown")
        trigger_type = payload.get("trigger_type", "unknown")
        cues_fired[cue_id] += 1
        cue_triggers[trigger_type] += 1

    if et == "session_end":
        duration_mins = payload.get("duration_minutes", 0)
        duration_cat = payload.get("duration_category", "unknown")
        if duration_mins > 0:
            session_durations.append({
                "session_id": session_id,
                "project": project,
                "duration_minutes": duration_mins,
                "category": duration_cat
            })
            duration_categories[duration_cat] += 1

    if et == "skill_invoked":
        skill_name = payload.get("skill", "unknown")
        skills_invoked[skill_name] += 1

    if et == "context_compact":
        context_compacts.append({
            "session_id": session_id,
            "project": project,
            "transcript_bytes": payload.get("transcript_bytes", 0),
            "message_count": payload.get("message_count", 0),
            "compaction_number": payload.get("compaction_number", 1)
        })

total_tests = test_results.get("passed", 0) + test_results.get("failed", 0)
pass_tests = test_results.get("passed", 0)
test_stability_rate = (pass_tests / total_tests) if total_tests else None
# Detailed test counts (from enriched events)
detailed_passed = test_results.get("_passed_count", 0)
detailed_failed = test_results.get("_failed_count", 0)
detailed_skipped = test_results.get("_skipped_count", 0)
failure_rate = (failures / len(events)) if events else 0.0

# Convert project stats for JSON (sets -> counts)
projects_summary = []
for proj, stats in sorted(project_stats.items(), key=lambda x: -x[1]["events"]):
    projects_summary.append({
        "project": proj,
        "events": stats["events"],
        "sessions": len(stats["sessions"]),
        "writes": stats["writes"],
        "failures": stats["failures"],
        "tradeoffs": stats["tradeoffs"],
        "large_changes": len(stats["large_change_files"]),
        "reversals": stats["reversals"]
    })

# FR-5: Schema with version and structured format
summary = {
    "schema_version": SCHEMA_VERSION,
    "week": {
        "start": week_start,
        "end": week_end,
        "generated_at": now.isoformat().replace("+00:00", "Z")
    },
    "totals": {
        "events": len(events),
        "sessions": len(set(e.get("session_id", "") for e in events)),
        "projects_touched": len(project_stats),
        "writes": writes,
        "failures": failures,
        "large_changes": len(large_change_files),
        "reversals": reversals,
        "decisions_documented": tradeoffs,
        "test_runs": total_tests,
        "dependency_changes": dependency_changes,
        "files_modified": len(files_modified)
    },
    "derived_metrics": {
        "failure_rate": round(failure_rate, 4),
        "test_stability_rate": round(test_stability_rate, 4) if test_stability_rate is not None else None,
        "test_runs_passed": pass_tests,
        "test_counts": {
            "passed": detailed_passed,
            "failed": detailed_failed,
            "skipped": detailed_skipped,
            "total": detailed_passed + detailed_failed + detailed_skipped
        }
    },
    "projects": projects_summary,
    "events_by_type": dict(by_type.most_common()),
    "top_friction_domains": [{"domain": d, "count": c} for d, c in friction_domains.most_common(10)],
    "top_friction_subdomains": [{"subdomain": d, "count": c} for d, c in friction_subdomains.most_common(10)],
    "top_principles_invoked": [{"principle": p, "count": c} for p, c in principles.most_common(10)],
    "top_skills_used": [{"skill": s, "count": c} for s, c in skills_used.most_common(10)],
    "top_files_modified": sorted(files_modified)[:20],
    "cue_engagement": {
        "total_fires": sum(cues_fired.values()),
        "unique_cues_fired": len(cues_fired),
        "by_cue": [{"cue": c, "count": n} for c, n in cues_fired.most_common(10)],
        "by_trigger": [{"trigger": t, "count": n} for t, n in cue_triggers.most_common()]
    },
    "session_duration": {
        "sessions_tracked": len(session_durations),
        "total_minutes": sum(s["duration_minutes"] for s in session_durations),
        "average_minutes": round(sum(s["duration_minutes"] for s in session_durations) / len(session_durations), 1) if session_durations else 0,
        "median_minutes": sorted([s["duration_minutes"] for s in session_durations])[len(session_durations)//2] if session_durations else 0,
        "longest_session": max((s["duration_minutes"] for s in session_durations), default=0),
        "by_category": [{"category": c, "count": n} for c, n in sorted(duration_categories.items(), key=lambda x: ["quick", "short", "medium", "long", "marathon", "unknown"].index(x[0]) if x[0] in ["quick", "short", "medium", "long", "marathon", "unknown"] else 99)],
        "by_project": [
            {"project": proj, "sessions": len([s for s in session_durations if s["project"] == proj]), "avg_minutes": round(sum(s["duration_minutes"] for s in session_durations if s["project"] == proj) / len([s for s in session_durations if s["project"] == proj]), 1) if [s for s in session_durations if s["project"] == proj] else 0}
            for proj in sorted(set(s["project"] for s in session_durations))
        ]
    },
    "skill_usage": {
        "total_invocations": sum(skills_invoked.values()),
        "unique_skills": len(skills_invoked),
        "by_skill": [{"skill": s, "count": n} for s, n in skills_invoked.most_common(15)]
    },
    "context_compaction": {
        "total_compactions": len(context_compacts),
        "sessions_with_compaction": len(set(c["session_id"] for c in context_compacts)),
        "avg_compactions_per_session": round(len(context_compacts) / len(set(c["session_id"] for c in context_compacts)), 1) if context_compacts else 0,
        "total_bytes_compacted": sum(c["transcript_bytes"] for c in context_compacts),
        "by_project": [
            {"project": proj, "compactions": len([c for c in context_compacts if c["project"] == proj])}
            for proj in sorted(set(c["project"] for c in context_compacts))
        ] if context_compacts else []
    }
}

with open(out_path, "w", encoding="utf-8") as out:
    json.dump(summary, out, indent=2)
PY

# FR-7: Log local summary
echo "✓ Wrote local summary: $SUMMARY_JSON" >&2

# ============================================================================
# FR-2: Publish to Jekyll
# ============================================================================

JEKYLL_SUMMARY="$DATA_DIR/${WEEK_START}-summary.json"
JEKYLL_REVIEW="$REVIEWS_DIR/${WEEK_START}-weekly-review.md"

# Copy summary JSON (overwrites safely)
cp "$SUMMARY_JSON" "$JEKYLL_SUMMARY"
echo "✓ Published summary to Jekyll: $JEKYLL_SUMMARY" >&2

# ============================================================================
# FR-3: Create post stub if missing
# ============================================================================

if [[ ! -f "$JEKYLL_REVIEW" ]]; then
  cat > "$JEKYLL_REVIEW" <<EOF
---
layout: review
title: "Weekly Engineering Review — ${WEEK_START}"
date: ${WEEK_START}
summary_file: ${WEEK_START}-summary.json
---

<!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->

## Executive Summary

_(AI synthesis will populate this section.)_

<!-- PLACEHOLDER:FRICTION_ANALYSIS -->

## Friction Analysis

_(Generated from summary data.)_

<!-- PLACEHOLDER:IMPACT_BULLETS -->

## Promotion-Ready Impact Bullets

-

<!-- PLACEHOLDER:PRECISION_MOVES -->

## Precision Moves for Next Week

-
EOF
  echo "✓ Created review: $JEKYLL_REVIEW" >&2
else
  echo "• Skipped: $JEKYLL_REVIEW already exists" >&2
fi

# Print output directory (for consumers)
echo "$OUT_DIR"
