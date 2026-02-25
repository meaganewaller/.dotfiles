#!/usr/bin/env bash
set -euo pipefail

OUT_DIR_BASE=".claude/reviews"

if [[ -f ".claude/dev-os-events.jsonl" ]]; then
  STREAM=".claude/dev-os-events.jsonl"
elif [[ -f "$HOME/.claude/dev-os-events.jsonl" ]]; then
  STREAM="$HOME/.claude/dev-os-events.jsonl"
else
  echo "Missing dev-os-events.jsonl (project and global)" >&2
  exit 1
fi

if [[ ! -f "$STREAM" ]]; then
  echo "Missing $STREAM" >&2
  exit 1
fi

mkdir -p "$OUT_DIR_BASE"

# Week folder: start-of-week (Monday) in UTC
# macOS: `date -u -v...` differs; use python for portability
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

python3 - <<'PY' "$STREAM" "$SUMMARY_JSON"
import json, sys, datetime as dt
from collections import Counter, defaultdict

stream_path, out_path = sys.argv[1], sys.argv[2]

def parse_ts(s: str):
  # Expect ISO8601, likely "YYYY-MM-DDTHH:MM:SSZ"
  if s.endswith("Z"):
    s = s[:-1] + "+00:00"
  return dt.datetime.fromisoformat(s)

now = dt.datetime.now(dt.timezone.utc)
since = now - dt.timedelta(days=7)

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
      events.append(e)

by_type = Counter(e.get("event_type","unknown") for e in events)

# Specific aggregations
friction_domains = Counter()
principles = Counter()
test_results = Counter()
large_changes = 0
reversals = 0
dependency_changes = 0
writes = 0
failures = 0
tradeoffs = 0

for e in events:
  et = e.get("event_type")
  payload = e.get("payload") or {}
  if et in ("tool_write",):
    writes += 1
  if et in ("tool_failure", "friction_event"):
    failures += 1
  if et in ("tool_failure", "friction_event"):
    d = payload.get("domain")
    if isinstance(d, str) and d.strip():
      friction_domains[d.strip()] += 1
  if et == "decision_tradeoff":
    tradeoffs += 1
    for p in payload.get("principles_invoked") or []:
      if isinstance(p, str) and p.strip():
        principles[p.strip()] += 1
  if et == "test_run":
    r = (payload.get("result") or "").strip().lower()
    if r:
      test_results[r] += 1
  if et == "large_change":
    large_changes += 1
  if et == "reversal":
    reversals += 1
  if et == "dependency_change":
    dependency_changes += 1

total_tests = sum(test_results.values())
pass_tests = test_results.get("passed", 0)
test_stability_rate = (pass_tests / total_tests) if total_tests else None

summary = {
  "window": {
    "since": since.isoformat().replace("+00:00", "Z"),
    "until": now.isoformat().replace("+00:00", "Z"),
    "days": 7
  },
  "counts": {
    "events_total": len(events),
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
  "events_by_type": dict(by_type.most_common()),
  "top_friction_domains": [{"domain": d, "count": c} for d, c in friction_domains.most_common(10)],
  "top_principles_invoked": [{"principle": p, "count": c} for p, c in principles.most_common(10)]
}

with open(out_path, "w", encoding="utf-8") as out:
  json.dump(summary, out, indent=2)
print(out_path)
PY

echo "✓ Wrote $SUMMARY_JSON"
echo "$OUT_DIR"
