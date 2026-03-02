# Weekly Review Pipeline - Manual Test Checklist

Use this checklist to verify the aggregate.sh script works correctly.

---

## Prerequisites

- [ ] At least one event stream exists with recent events:
  - `~/.codex/dev-os-events.jsonl`
  - `~/.claude/dev-os-events.jsonl`
- [ ] `jq` is installed
- [ ] `python3` is installed
- [ ] Jekyll repository exists at expected path

---

## Test 1: Happy Path

```bash
# Run the script
~/.codex/devos/skills/weekly-review/scripts/aggregate.sh
```

**Expected output:**
```
✓ Wrote local summary: ~/.codex/devos/reviews/week-of-YYYY-MM-DD/summary.json
✓ Published summary to Jekyll: ~/github/meaganewaller/weekly-reviews/_data/dev_os/YYYY-MM-DD-summary.json
✓ Created post: ~/github/meaganewaller/weekly-reviews/_posts/YYYY-MM-DD-weekly-review.md
~/.codex/devos/reviews/week-of-YYYY-MM-DD
```

**Verify:**
- [ ] Local summary exists: `ls ~/.codex/devos/reviews/week-of-*/summary.json`
- [ ] Jekyll summary exists: `ls ~/github/meaganewaller/weekly-reviews/_data/dev_os/*-summary.json`
- [ ] Jekyll post exists: `ls ~/github/meaganewaller/weekly-reviews/_posts/*-weekly-review.md`

---

## Test 2: Schema Version Present

```bash
jq '.schema_version' ~/.codex/devos/reviews/week-of-*/summary.json
```

**Expected:** `"1.0.0"`

- [ ] Schema version is present and correct

---

## Test 3: Week Dates Correct

```bash
jq '.week' ~/.codex/devos/reviews/week-of-*/summary.json
```

**Expected:**
```json
{
  "start": "YYYY-MM-DD",  // Should be a Monday
  "end": "YYYY-MM-DD",    // Should be following Sunday
  "generated_at": "..."   // ISO8601 timestamp
}
```

- [ ] `start` is a Monday
- [ ] `end` is 6 days after start
- [ ] `generated_at` is valid ISO8601

---

## Test 4: Idempotency - Second Run

```bash
# Run again
~/.codex/devos/skills/weekly-review/scripts/aggregate.sh
```

**Expected output:**
```
✓ Wrote local summary: ...
✓ Published summary to Jekyll: ...
• Skipped: .../YYYY-MM-DD-weekly-review.md already exists
```

**Verify:**
- [ ] Post was NOT recreated (message says "Skipped")
- [ ] Summary JSON was updated (check timestamp)
- [ ] No duplicate files created

---

## Test 5: Missing All Event Streams

```bash
# Temporarily point to non-existent streams
export CODEX_EVENT_STREAMS="/tmp/nope-a.jsonl:/tmp/nope-b.jsonl"

# Run script
~/.codex/devos/skills/weekly-review/scripts/aggregate.sh

# Restore default behavior
unset CODEX_EVENT_STREAMS
```

**Expected:**
- [ ] Exit code is 1: `echo $?` → `1`
- [ ] Error mentions missing event streams and checked defaults

---

## Test 6: Missing Jekyll Root

```bash
# Run with non-existent Jekyll root
JEKYLL_ROOT=/tmp/nonexistent ~/.codex/devos/skills/weekly-review/scripts/aggregate.sh
```

**Expected:**
- [ ] Exit code is 1
- [ ] Error message: `Error: Jekyll root directory does not exist: /tmp/nonexistent`

---

## Test 7: Totals Structure

```bash
jq '.totals | keys' ~/.codex/devos/reviews/week-of-*/summary.json
```

**Expected keys:**
```json
[
  "decisions_documented",
  "dependency_changes",
  "events",
  "failures",
  "files_modified",
  "large_changes",
  "projects_touched",
  "reversals",
  "sessions",
  "test_runs",
  "writes"
]
```

- [ ] All expected keys present

---

## Test 8: Derived Metrics

```bash
jq '.derived_metrics' ~/.codex/devos/reviews/week-of-*/summary.json
```

**Expected:**
```json
{
  "failure_rate": <number between 0 and 1>,
  "test_stability_rate": <number or null>,
  "test_runs_passed": <number>
}
```

- [ ] `failure_rate` is a decimal (0.0 - 1.0)
- [ ] `test_stability_rate` is number or null
- [ ] `test_runs_passed` is present

---

## Test 9: Jekyll Post Format

```bash
head -20 ~/github/meaganewaller/weekly-reviews/_posts/*-weekly-review.md
```

**Expected frontmatter:**
```yaml
---
layout: review
title: "Weekly Engineering Review — YYYY-MM-DD"
date: YYYY-MM-DD
summary_file: YYYY-MM-DD-summary.json
---
```

- [ ] `layout: review` is present
- [ ] `summary_file` matches the data file name
- [ ] Date in title matches filename

---

## Test 10: Full Pipeline Integration

```bash
# Run full pipeline
~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh
```

**Verify all artifacts:**
- [ ] `summary.json` exists
- [ ] `review.md` exists
- [ ] `index.html` exists
- [ ] Jekyll `_data/dev_os/*.json` updated
- [ ] Jekyll `_posts/*.md` exists

---

## Cleanup (Optional)

To reset for fresh testing:

```bash
# Remove local review (preserves events)
rm -rf ~/.codex/devos/reviews/week-of-$(date -u +%Y-%m-%d -d 'last monday')

# Remove Jekyll artifacts (careful!)
rm ~/github/meaganewaller/weekly-reviews/_data/dev_os/*-summary.json
rm ~/github/meaganewaller/weekly-reviews/_posts/*-weekly-review.md
```

---

## Results Summary

| Test | Pass/Fail | Notes |
|------|-----------|-------|
| 1. Happy path | | |
| 2. Schema version | | |
| 3. Week dates | | |
| 4. Idempotency | | |
| 5. Missing events | | |
| 6. Missing Jekyll | | |
| 7. Totals structure | | |
| 8. Derived metrics | | |
| 9. Post format | | |
| 10. Full pipeline | | |

**Tested by:** _______________
**Date:** _______________
