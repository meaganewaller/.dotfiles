#!/usr/bin/env bash
# Aggregates yesterday's dev-os events for standup
set -euo pipefail

EVENTS_LOG="${CLAUDE_EVENTS_LOG:-$HOME/.claude/dev-os-events.jsonl}"

if [[ ! -f "$EVENTS_LOG" ]]; then
  echo "No events log found at $EVENTS_LOG"
  exit 0
fi

# Get yesterday's date range (UTC)
YESTERDAY=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d "yesterday" +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

python3 - <<PY "$EVENTS_LOG" "$YESTERDAY" "$TODAY"
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime

events_log = sys.argv[1]
yesterday = sys.argv[2]
today = sys.argv[3]

# Read and filter yesterday's events
events = []
with open(events_log, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
            ts = e.get('timestamp', '')[:10]
            if ts == yesterday:
                events.append(e)
        except:
            continue

if not events:
    print(f"No events found for {yesterday}")
    sys.exit(0)

# Aggregate metrics
writes = 0
files_modified = set()
decisions = []
sessions = set()
session_minutes = 0
compactions = 0
failures = 0
friction_domains = Counter()
skills_used = Counter()

for e in events:
    et = e.get('event_type', '')
    payload = e.get('payload', {}) or {}
    session_id = e.get('session_id', '')

    if session_id:
        sessions.add(session_id)

    if et == 'tool_write':
        writes += 1
        f = payload.get('file', '')
        if f:
            # Get just filename for brevity
            files_modified.add(f.split('/')[-1])

    if et == 'decision_tradeoff':
        summary = payload.get('decision_summary', '')
        if summary:
            decisions.append(summary[:100])

    if et == 'session_end':
        mins = payload.get('duration_minutes', 0)
        session_minutes += mins

    if et == 'context_compact':
        compactions += 1

    if et in ('tool_failure', 'friction_event'):
        failures += 1
        domain = payload.get('domain', 'unknown')
        friction_domains[domain] += 1

    if et == 'skill_invoked':
        skill = payload.get('skill', '')
        if skill:
            skills_used[skill] += 1

# Output summary
print(f"## Standup Data for {yesterday}")
print()
print(f"### Activity")
print(f"- Sessions: {len(sessions)}")
print(f"- Total time: {session_minutes} minutes ({session_minutes/60:.1f} hours)")
print(f"- Writes: {writes}")
print(f"- Files modified: {len(files_modified)}")
print(f"- Context compactions: {compactions}")
print()

if files_modified:
    print(f"### Files Modified")
    for f in sorted(list(files_modified)[:15]):
        print(f"- {f}")
    if len(files_modified) > 15:
        print(f"- ... and {len(files_modified) - 15} more")
    print()

if decisions:
    print(f"### Decisions Made")
    for d in decisions[:5]:
        print(f"- {d}")
    print()

if skills_used:
    print(f"### Skills Used")
    for skill, count in skills_used.most_common(5):
        print(f"- {skill}: {count}x")
    print()

if failures > 0:
    print(f"### Friction")
    print(f"- Total failures: {failures}")
    for domain, count in friction_domains.most_common(3):
        print(f"- {domain}: {count}")
    print()

print(f"### Blockers")
if failures > 50:
    print(f"- High friction rate ({failures} failures) - investigate {friction_domains.most_common(1)[0][0]} domain")
else:
    print("- None identified")
PY
