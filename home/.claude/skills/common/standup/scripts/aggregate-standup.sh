#!/usr/bin/env bash
# Aggregates yesterday's dev-os events for standup
set -euo pipefail

EVENTS_LOG="${CLAUDE_EVENTS_LOG:-$HOME/.claude/dev-os-events.jsonl}"

# Get yesterday's date range (UTC)
YESTERDAY=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d "yesterday" +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

# ============================================================================
# GitHub PR Data (optional - requires gh CLI)
# ============================================================================

GH_DATA=""
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  # Fetch PRs opened yesterday (across ALL repos)
  PRS_OPENED=$(gh search prs --author=@me --limit 50 "created:$YESTERDAY" --json number,title,url,repository,state 2>/dev/null || echo "[]")

  # Fetch PRs merged yesterday (across ALL repos)
  PRS_MERGED=$(gh search prs --author=@me --merged --limit 50 "merged:$YESTERDAY" --json number,title,url,repository 2>/dev/null || echo "[]")

  # Fetch PRs where review was requested from me (across ALL repos)
  PRS_REVIEW=$(gh search prs --review-requested=@me --state=open --limit 20 --json number,title,url,repository 2>/dev/null || echo "[]")

  GH_DATA=$(cat <<EOF
{
  "prs_opened": $PRS_OPENED,
  "prs_merged": $PRS_MERGED,
  "prs_review_requested": $PRS_REVIEW
}
EOF
)
fi

# ============================================================================
# Aggregate and Output
# ============================================================================

python3 - <<PY "$EVENTS_LOG" "$YESTERDAY" "$TODAY" "$GH_DATA"
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime

events_log = sys.argv[1]
yesterday = sys.argv[2]
today = sys.argv[3]
gh_data_raw = sys.argv[4] if len(sys.argv) > 4 else ""

# Parse GitHub data
gh_data = {}
if gh_data_raw:
    try:
        gh_data = json.loads(gh_data_raw)
    except:
        pass

# Read and filter yesterday's events
events = []
try:
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
except FileNotFoundError:
    pass

has_events = len(events) > 0
has_gh_data = bool(gh_data.get('prs_opened') or gh_data.get('prs_merged'))

if not has_events and not has_gh_data:
    print(f"No events or PR activity found for {yesterday}")
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

# GitHub PR Activity
prs_opened = gh_data.get('prs_opened', [])
prs_merged = gh_data.get('prs_merged', [])
prs_review = gh_data.get('prs_review_requested', [])

if prs_opened or prs_merged:
    print(f"### Pull Requests")
    if prs_opened:
        print(f"**Opened ({len(prs_opened)}):**")
        for pr in prs_opened[:5]:
            repo = pr.get('repository', {}).get('name', '')
            title = pr.get('title', '')[:60]
            url = pr.get('url', '')
            state = pr.get('state', '').upper()
            repo_prefix = f"[{repo}] " if repo else ""
            print(f"- {repo_prefix}{title} ({state})")
        print()
    if prs_merged:
        print(f"**Merged ({len(prs_merged)}):**")
        for pr in prs_merged[:5]:
            repo = pr.get('repository', {}).get('name', '')
            title = pr.get('title', '')[:60]
            repo_prefix = f"[{repo}] " if repo else ""
            print(f"- {repo_prefix}{title}")
        print()

if prs_review:
    print(f"### Pending Reviews ({len(prs_review)})")
    for pr in prs_review[:5]:
        repo = pr.get('repository', {}).get('name', '')
        title = pr.get('title', '')[:60]
        url = pr.get('url', '')
        repo_prefix = f"[{repo}] " if repo else ""
        print(f"- {repo_prefix}{title}")
    print()

print(f"### Blockers")
if failures > 50:
    print(f"- High friction rate ({failures} failures) - investigate {friction_domains.most_common(1)[0][0]} domain")
else:
    print("- None identified")
PY
