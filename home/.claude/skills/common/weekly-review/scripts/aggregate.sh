#!/usr/bin/env bash
set -euo pipefail

OUT_DIR_BASE="$HOME/.claude/reviews"
PROJECTS_DIR="$HOME/.claude/projects"
GLOBAL_STREAM="$HOME/.claude/dev-os-events.jsonl"

# Require global stream
if [[ ! -f "$GLOBAL_STREAM" ]]; then
  echo "Missing $GLOBAL_STREAM" >&2
  exit 1
fi

mkdir -p "$OUT_DIR_BASE"

# Week folder: start-of-week (Monday) in UTC
WEEK_START=$(python3 - <<'PY'
import datetime as dt
now = dt.datetime.now(dt.timezone.utc)
monday = now - dt.timedelta(days=now.weekday())
monday = dt.datetime(monday.year, monday.month, monday.day, tzinfo=dt.timezone.utc)
print(monday.date().isoformat())
PY
)

OUT_DIR="$OUT_DIR_BASE/week-of-$WEEK_START"
mkdir -p "$OUT_DIR"

SUMMARY_JSON="$OUT_DIR/summary.json"

# Run Python aggregation with project mapping
python3 - <<'PY' "$GLOBAL_STREAM" "$PROJECTS_DIR" "$SUMMARY_JSON"
import json, sys, os, datetime as dt
from collections import Counter, defaultdict
from pathlib import Path

stream_path, projects_dir, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

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
        # Find session files (UUID.jsonl)
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

# Build session -> project mapping
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
            # Enrich with project info
            session_id = e.get("session_id", "")
            if session_id in session_map:
                e["_project"] = session_map[session_id]
            else:
                e["_project"] = {"project_short": "unknown", "project_path": "unknown"}
            events.append(e)

by_type = Counter(e.get("event_type", "unknown") for e in events)

# Per-project aggregations
project_stats = defaultdict(lambda: {
    "events": 0, "writes": 0, "failures": 0, "tradeoffs": 0,
    "large_changes": 0, "reversals": 0, "sessions": set()
})

# Global aggregations
friction_domains = Counter()
friction_subdomains = Counter()
principles = Counter()
test_results = Counter()
large_changes = 0
reversals = 0
dependency_changes = 0
writes = 0
failures = 0
tradeoffs = 0
files_modified = set()
skills_used = Counter()

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
        # Handle new structured friction_domain
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

    if et == "large_change":
        large_changes += 1
        project_stats[project]["large_changes"] += 1

    if et == "reversal":
        reversals += 1
        project_stats[project]["reversals"] += 1

    if et == "dependency_change":
        dependency_changes += 1

total_tests = sum(test_results.values())
pass_tests = test_results.get("passed", 0)
test_stability_rate = (pass_tests / total_tests) if total_tests else None

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
        "large_changes": stats["large_changes"],
        "reversals": stats["reversals"]
    })

summary = {
    "window": {
        "since": since.isoformat().replace("+00:00", "Z"),
        "until": now.isoformat().replace("+00:00", "Z"),
        "days": 7
    },
    "counts": {
        "events_total": len(events),
        "projects_touched": len(project_stats),
        "sessions_total": len(set(e.get("session_id", "") for e in events)),
        "files_modified": len(files_modified),
        "writes": writes,
        "failures": failures,
        "tradeoff_events": tradeoffs,
        "large_change_events": large_changes,
        "reversal_events": reversals,
        "dependency_change_events": dependency_changes,
        "test_runs_total": total_tests,
        "test_runs_passed": pass_tests,
        "test_stability_rate": test_stability_rate
    },
    "projects": projects_summary,
    "events_by_type": dict(by_type.most_common()),
    "top_friction_domains": [{"domain": d, "count": c} for d, c in friction_domains.most_common(10)],
    "top_friction_subdomains": [{"subdomain": d, "count": c} for d, c in friction_subdomains.most_common(10)],
    "top_principles_invoked": [{"principle": p, "count": c} for p, c in principles.most_common(10)],
    "top_skills_used": [{"skill": s, "count": c} for s, c in skills_used.most_common(10)],
    "top_files_modified": sorted(files_modified)[:20]
}

with open(out_path, "w", encoding="utf-8") as out:
    json.dump(summary, out, indent=2)

print(out_path, file=sys.stderr)
PY

echo "✓ Wrote $SUMMARY_JSON" >&2
echo "$OUT_DIR"
