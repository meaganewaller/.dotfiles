#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
# Usage: aggregate.sh [WEEK_OFFSET]
#   WEEK_OFFSET: 0 = current week (default), -1 = last week, -2 = two weeks ago, etc.

OUT_DIR_BASE="$HOME/.claude/reviews"
PROJECTS_DIR="$HOME/.claude/projects"
GLOBAL_STREAM="$HOME/.claude/dev-os-events.jsonl"
JEKYLL_ROOT="${JEKYLL_ROOT:-$HOME/github/meaganewaller/weekly-reviews}"
WEEK_OFFSET="${1:-0}"

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
# WEEK_OFFSET: 0 = current week, -1 = last week, -2 = two weeks ago, etc.

read -r WEEK_START WEEK_END < <(python3 - "$WEEK_OFFSET" <<'PY'
import datetime as dt
import sys

week_offset = int(sys.argv[1]) if len(sys.argv) > 1 else 0

now = dt.datetime.now(dt.timezone.utc)
# Apply week offset (negative = past weeks)
target_day = now + dt.timedelta(weeks=week_offset)
monday = target_day - dt.timedelta(days=target_day.weekday())
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

def encode_path(path: str) -> str:
    """Encode a path the same way Claude Code does: replace / and . with -"""
    return path.replace("/", "-").replace(".", "-")

def infer_project_from_paths(file_paths: list, projects_dir: str) -> dict:
    """Infer project from file paths by matching against known project directories"""
    if not file_paths:
        return None
    projects_path = Path(projects_dir)
    if not projects_path.exists():
        return None

    # Get all known project directories
    project_dirs = {}
    for project_dir in projects_path.iterdir():
        if not project_dir.is_dir() or project_dir.name.startswith("."):
            continue
        # Extract the short name (last path component, approximated)
        parts = project_dir.name.lstrip("-").split("-")
        short_name = parts[-1] if parts else project_dir.name
        project_dirs[project_dir.name] = {
            "project_path": project_dir.name,
            "project_dir": project_dir.name,
            "project_short": short_name
        }

    # Try to match file paths to projects by encoding the file path
    for fp in file_paths:
        if not isinstance(fp, str):
            continue
        encoded_fp = encode_path(fp)
        for proj_name, proj_info in project_dirs.items():
            # Check if the encoded file path starts with the project directory name
            if encoded_fp.startswith(proj_name):
                return proj_info
    return None

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
# Use week boundaries for filtering instead of rolling 7-day window
week_start_dt = dt.datetime.fromisoformat(week_start + "T00:00:00+00:00")
week_end_dt = dt.datetime.fromisoformat(week_end + "T23:59:59+00:00")

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
        if not isinstance(e, dict):
            continue
        ts = e.get("timestamp")
        if not ts:
            continue
        try:
            t = parse_ts(ts).astimezone(dt.timezone.utc)
        except Exception:
            continue
        # Filter events within the week boundaries
        if week_start_dt <= t <= week_end_dt:
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
                # For decision_tradeoff events, try to infer project from files_changed
                inferred = None
                if event_type == "decision_tradeoff":
                    payload = e.get("payload")
                    if isinstance(payload, dict):
                        files_changed = payload.get("files_changed") or []
                        inferred = infer_project_from_paths(files_changed, projects_dir)
                e["_project"] = inferred or {"project_short": "unknown", "project_path": "unknown"}
            events.append(e)

# Second pass: correlate unattributed tradeoffs with write events
# Build file->project map from write events (both full paths and basenames)
import os.path as osp
file_to_project = {}
for e in events:
    if e.get("event_type") == "tool_write":
        proj_info = e.get("_project", {})
        proj_short = proj_info.get("project_short", "unknown")
        if proj_short != "unknown":
            f = (e.get("payload") or {}).get("file", "")
            if f:
                # Store both full path and basename for matching
                file_to_project[f] = proj_info
                file_to_project[osp.basename(f)] = proj_info

# Build decision journal context map AND read decisions directly from journal
import re
import glob
journal_dir = Path.home() / ".claude" / "decision-journal"
journal_context = {}  # Maps date prefix (e.g., "2026-03-02") to project info
journal_decisions = []  # Decisions read directly from journal files (primary source)

def extract_list_items(content: str, header: str) -> list:
    """Extract list items following a markdown header"""
    pattern = rf"## {header}\s*\n((?:[-*]\s*.+\n?)+)"
    match = re.search(pattern, content, re.IGNORECASE)
    if match:
        items = re.findall(r"[-*]\s*(.+)", match.group(1))
        return [item.strip() for item in items if item.strip()]
    return []

def infer_project_from_content(content: str) -> str:
    """Infer project from decision journal content"""
    content_lower = content.lower()
    if "pull" in content_lower or "gusto" in content_lower or "database" in content_lower:
        return "pull"
    elif "dotfiles" in content_lower or "claude" in content_lower:
        return ".dotfiles"
    elif "review" in content_lower or "weekly" in content_lower:
        return "reviews"
    return "unknown"

if journal_dir.exists():
    for jf in journal_dir.glob("*.md"):
        # Extract date from filename (e.g., 2026-03-02-1500-template-context-extraction.md)
        match = re.match(r"(\d{4}-\d{2}-\d{2})", jf.name)
        if not match:
            continue
        date_prefix = match.group(1)

        # Only include decisions from this week
        if date_prefix < week_start or date_prefix > week_end:
            continue

        try:
            content = jf.read_text(encoding="utf-8")

            # Extract decision summary (first paragraph after # Tradeoff: or ## Decision Summary)
            summary_match = re.search(r"## Decision Summary\s*\n\s*(.+?)(?:\n\n|\n##)", content, re.DOTALL)
            if not summary_match:
                summary_match = re.search(r"## What Was Chosen\s*\n\s*(.+?)(?:\n\n|\n##)", content, re.DOTALL)
            decision_summary = summary_match.group(1).strip() if summary_match else jf.stem

            # Extract structured fields
            tradeoffs = extract_list_items(content, "Trade-offs")
            alternatives = extract_list_items(content, "Alternatives Considered")
            principles = extract_list_items(content, "Principles Applied")

            # Extract source (auto-capture, subagent-capture, or manual)
            source_match = re.search(r"\*\*Source:\*\*\s*(.+)", content)
            source = source_match.group(1).strip() if source_match else "manual"

            # Infer project
            project = infer_project_from_content(content)

            journal_decisions.append({
                "file": jf.name,
                "date": date_prefix,
                "decision_summary": decision_summary[:200],  # Truncate for summary
                "tradeoffs": tradeoffs,
                "options_considered": alternatives,
                "principles_invoked": principles,
                "source": source,
                "project": project
            })

            # Also maintain context map for attribution of JSONL events
            if date_prefix not in journal_context:
                journal_context[date_prefix] = []
            journal_context[date_prefix].append({
                "project_short": project,
                "project_path": project,
                "context": decision_summary[:100]
            })

        except Exception:
            continue

# Now try to attribute unattributed tradeoff events
for e in events:
    if e.get("event_type") != "decision_tradeoff":
        continue
    proj_info = e.get("_project", {})
    if proj_info.get("project_short", "unknown") != "unknown":
        continue  # Already attributed

    # Try to match files_changed against our file->project map
    payload = e.get("payload") or {}
    files_changed = payload.get("files_changed") or []
    matched = False
    for fname in files_changed:
        if not isinstance(fname, str):
            continue
        # Try exact match first, then basename
        if fname in file_to_project:
            e["_project"] = file_to_project[fname]
            matched = True
            break
        basename = osp.basename(fname)
        if basename in file_to_project:
            e["_project"] = file_to_project[basename]
            matched = True
            break

    # Fallback: try to match by date to decision journal entries
    if not matched:
        ts = e.get("timestamp", "")
        if ts:
            date_prefix = ts[:10]  # Extract YYYY-MM-DD
            if date_prefix in journal_context:
                # Use the first matching journal entry for this date
                e["_project"] = journal_context[date_prefix][0]

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
test_runs_by_session = defaultdict(list)  # Track test runs by session for stability analysis

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
        # Track by session for stable session analysis (ADR-0009)
        error_excerpt = payload.get("error_excerpt", "")
        test_runs_by_session[session_id].append({
            "result": r,
            "error_excerpt": error_excerpt,
            "is_sqlite_error": "SQLite3" in (error_excerpt or "")
        })

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

# Count journal decisions (primary source) - add to totals and principles
journal_tradeoffs = len(journal_decisions)
for jd in journal_decisions:
    project = jd.get("project", "unknown")
    project_stats[project]["tradeoffs"] += 1
    for p in jd.get("principles_invoked") or []:
        if isinstance(p, str) and p.strip():
            principles[p.strip()] += 1

# ============================================================================
# Stable Session Metrics (ADR-0009)
# ============================================================================
# Classify sessions by stability pattern:
# - stable: >=70% pass rate (working code, occasional failures are flaky)
# - dev-iteration: >=70% fail rate (expected TDD cycle)
# - mixed: transitional states
def classify_session(runs):
    if not runs:
        return "empty"
    passed = sum(1 for r in runs if r["result"] == "passed")
    total = len(runs)
    pass_rate = passed / total
    if pass_rate >= 0.7:
        return "stable"
    elif pass_rate <= 0.3:
        return "dev-iteration"
    return "mixed"

session_classifications = {}
stable_session_runs = []
sqlite_errors = 0
for sid, runs in test_runs_by_session.items():
    classification = classify_session(runs)
    session_classifications[sid] = classification
    # Count SQLite environmental errors
    sqlite_errors += sum(1 for r in runs if r.get("is_sqlite_error"))
    # Collect runs from stable sessions for true stability calculation
    if classification == "stable":
        stable_session_runs.extend(runs)

# Calculate metrics
stable_session_passed = sum(1 for r in stable_session_runs if r["result"] == "passed")
stable_session_total = len(stable_session_runs)
stable_session_stability = (stable_session_passed / stable_session_total) if stable_session_total else None

session_pattern_counts = Counter(session_classifications.values())

# Original (raw) metrics for comparison
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
        "decisions_documented": tradeoffs + journal_tradeoffs,
        "decisions_from_journal": journal_tradeoffs,
        "decisions_from_events": tradeoffs,
        "test_runs": total_tests,
        "dependency_changes": dependency_changes,
        "files_modified": len(files_modified)
    },
    "derived_metrics": {
        "failure_rate": round(failure_rate, 4),
        # ADR-0009: Stable session stability is the primary metric
        "test_stability": {
            "stable_session_rate": round(stable_session_stability, 4) if stable_session_stability is not None else None,
            "stable_session_runs": stable_session_total,
            "stable_session_passed": stable_session_passed,
            "raw_rate": round(test_stability_rate, 4) if test_stability_rate is not None else None,
            "raw_runs": total_tests,
            "raw_passed": pass_tests,
            "sqlite_environmental_errors": sqlite_errors,
            "session_patterns": {
                "stable": session_pattern_counts.get("stable", 0),
                "dev_iteration": session_pattern_counts.get("dev-iteration", 0),
                "mixed": session_pattern_counts.get("mixed", 0)
            }
        },
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
    "decisions": {
        "from_journal": [
            {
                "file": d["file"],
                "date": d["date"],
                "summary": d["decision_summary"],
                "project": d["project"],
                "source": d["source"],
                "tradeoffs_count": len(d.get("tradeoffs", [])),
                "principles_count": len(d.get("principles_invoked", []))
            }
            for d in journal_decisions
        ],
        "total_from_journal": journal_tradeoffs,
        "total_from_events": tradeoffs,
        "capture_sources": Counter(d["source"] for d in journal_decisions).most_common()
    },
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

<!-- PLACEHOLDER:DECISIONS_DOCUMENTED -->

## Decisions Documented

_(Summary of architectural decisions from the week.)_

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
