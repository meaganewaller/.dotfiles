# Weekly Review Pipeline Contracts

This document defines the explicit interface contracts between pipeline scripts.
These contracts convert implicit coupling into testable boundaries.

## Pipeline Overview

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌────────────────────┐
│  aggregate.sh   │────▶│  charts.py   │────▶│  render_md.sh   │────▶│ render_dashboard.py│
│                 │     │  (optional)  │     │                 │     │                    │
│ OUT: summary.json     │ OUT: *.png   │     │ OUT: review.md  │     │ OUT: index.html    │
└─────────────────┘     └──────────────┘     └─────────────────┘     └────────────────────┘
        │                                                                      │
        └──────────────────────────────────────────────────────────────────────┘
                              Orchestrated by: run_weekly_review.sh
```

---

## 1. aggregate.sh

### Purpose
Aggregates dev-os events from the past 7 days across all projects into a structured summary.

### Input

| Source | Type | Required | Description |
|--------|------|----------|-------------|
| `~/.claude/dev-os-events.jsonl` | File | **Yes** | JSONL stream of dev-os events |
| `~/.claude/projects/` | Directory | No | Project directories for session→project mapping |

#### Input Event Schema (dev-os-events.jsonl)

Each line must be valid JSON with these fields:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",  // Required: ISO8601 UTC
  "session_id": "uuid-string",           // Required: Session identifier
  "event_type": "tool_write",            // Required: Event type enum
  "payload": { ... }                     // Optional: Event-specific data
}
```

**Supported event_type values:**
- `tool_write` - File write operation
- `tool_failure` - Tool execution failure
- `friction_event` - Friction/error event
- `decision_tradeoff` - Architectural decision
- `test_run` - Test execution
- `large_change` - Large file change
- `reversal` - Code reversal
- `dependency_change` - Dependency modification

### Output

| Destination | Type | Description |
|-------------|------|-------------|
| `~/.claude/reviews/week-of-YYYY-MM-DD/summary.json` | File | Aggregated summary |
| `stdout` | String | Output directory path |
| `stderr` | String | Progress messages |

#### Output Schema (summary.json)

```typescript
interface SummaryJSON {
  window: {
    since: string;      // ISO8601 UTC timestamp
    until: string;      // ISO8601 UTC timestamp
    days: number;       // Always 7
  };
  counts: {
    events_total: number;
    projects_touched: number;
    sessions_total: number;
    files_modified: number;
    writes: number;
    failures: number;
    tradeoff_events: number;
    large_change_events: number;
    reversal_events: number;
    dependency_change_events: number;
    test_runs_total: number;
    test_runs_passed: number;
    test_stability_rate: number | null;  // null if no tests
  };
  projects: Array<{
    project: string;      // Short project name
    events: number;
    sessions: number;
    writes: number;
    failures: number;
    tradeoffs: number;
    large_changes: number;
    reversals: number;
  }>;
  events_by_type: Record<string, number>;
  top_friction_domains: Array<{ domain: string; count: number }>;
  top_friction_subdomains: Array<{ subdomain: string; count: number }>;
  top_principles_invoked: Array<{ principle: string; count: number }>;
  top_skills_used: Array<{ skill: string; count: number }>;
  top_files_modified: string[];  // Max 20 items
}
```

### Error Handling

| Condition | Exit Code | Stderr Message |
|-----------|-----------|----------------|
| Missing dev-os-events.jsonl | 1 | `Missing ~/.claude/dev-os-events.jsonl` |
| Invalid JSON lines | 0 | Silently skipped |
| Missing projects directory | 0 | Continues with empty session map |
| Python error | 1 | Python traceback |

### Invariants

- Output directory is always `~/.claude/reviews/week-of-{monday-date}/`
- Week start is always Monday (UTC)
- Only events from past 7 days are included
- Arrays are sorted by count descending (most common first)
- `top_*` arrays are limited to 10 items max (except files: 20)

---

## 2. render_md.sh

### Purpose
Generates a markdown review document with placeholders for AI synthesis.

### Input

| Source | Type | Required | Description |
|--------|------|----------|-------------|
| `$1` | Argument | **Yes** | Path to summary.json |

The input must conform to the `SummaryJSON` schema defined above.

### Output

| Destination | Type | Description |
|-------------|------|-------------|
| `{summary_dir}/review.md` | File | Markdown review with placeholders |
| `stdout` | String | Confirmation message |

#### Output Structure (review.md)

```markdown
# Weekly Engineering Review

**Window:** {since} → {until}

## 📝 Executive Summary
<!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->
_Claude will synthesize execution quality, risk, and discipline here._
<!-- END:EXECUTIVE_SUMMARY -->

## 📊 Execution Metrics
### Overview
| Metric | Value |
|--------|-------|
...

### Per-Project Breakdown
| Project | Events | Sessions | Writes | Failures | Tradeoffs |
...

## 🔁 Repeated Friction
### By Domain
...
### By Subdomain
...
### Analysis
<!-- PLACEHOLDER:FRICTION_ANALYSIS -->
...
<!-- END:FRICTION_ANALYSIS -->

## 🧠 Architectural Thinking
### Principles Invoked
...
### Skills Demonstrated
...
### Analysis
<!-- PLACEHOLDER:ARCHITECTURE_ANALYSIS -->
...
<!-- END:ARCHITECTURE_ANALYSIS -->

## ⚠️ Discipline Flags
<!-- PLACEHOLDER:DISCIPLINE_FLAGS -->
...
<!-- END:DISCIPLINE_FLAGS -->

## 📁 Files Modified
...

## 📈 Charts
...

## 🚀 Promotion-Ready Impact Bullets
<!-- PLACEHOLDER:IMPACT_BULLETS -->
...
<!-- END:IMPACT_BULLETS -->

## 🎯 Precision Moves for Next Week
<!-- PLACEHOLDER:PRECISION_MOVES -->
...
<!-- END:PRECISION_MOVES -->
```

#### Placeholder Contract

Placeholders follow this exact format:
```
<!-- PLACEHOLDER:{NAME} -->
{placeholder_text}
<!-- END:{NAME} -->
```

**Placeholder names (6 total):**
1. `EXECUTIVE_SUMMARY`
2. `FRICTION_ANALYSIS`
3. `ARCHITECTURE_ANALYSIS`
4. `DISCIPLINE_FLAGS`
5. `IMPACT_BULLETS`
6. `PRECISION_MOVES`

Consumers (AI agents) must replace the entire block including comment markers.

### Error Handling

| Condition | Exit Code | Stderr Message |
|-----------|-----------|----------------|
| No argument provided | 1 | `Usage: render_md.sh path/to/summary.json` |
| File doesn't exist | 1 | `Usage: render_md.sh path/to/summary.json` |
| jq parse error | 1 | jq error message |
| bc not available | 1 | Shell error |

### Dependencies

- `jq` - JSON parsing
- `bc` - Floating-point arithmetic

---

## 3. render_dashboard.py

### Purpose
Generates an interactive HTML dashboard with tabs for Dashboard, Review, and Data views.

### Input

| Source | Type | Required | Description |
|--------|------|----------|-------------|
| `sys.argv[1]` | Argument | **Yes** | Path to summary.json |
| `{summary_dir}/review.md` | File | No | Markdown review (optional) |
| `{summary_dir}/charts/*.png` | Files | No | Chart images (optional) |

### Output

| Destination | Type | Description |
|-------------|------|-------------|
| `{summary_dir}/index.html` | File | Interactive HTML dashboard |
| `stdout` | String | Output file path |

#### Output Features

- **Dashboard tab**: Metric cards, per-project table, friction/principles lists, charts
- **Review tab**: Rendered markdown as styled HTML
- **Data tab**: Syntax-highlighted JSON viewer
- **Footer**: Links to raw files, generation timestamp

### Error Handling

| Condition | Behavior |
|-----------|----------|
| summary.json not found | Python FileNotFoundError exception |
| review.md not found | Review tab shows "No review content generated yet." |
| Chart images not found | Shows "Chart not generated" placeholder |
| Invalid JSON | Python JSONDecodeError exception |

### Dependencies

- Python 3.6+
- No external packages required

---

## 4. charts.py

### Purpose
Generates visualization charts from summary data.

### Input

| Source | Type | Required | Description |
|--------|------|----------|-------------|
| `sys.argv[1]` | Argument | **Yes** | Path to summary.json |

### Output

| Destination | Type | Description |
|-------------|------|-------------|
| `{summary_dir}/charts/events_by_type.png` | File | Bar chart of event distribution |
| `{summary_dir}/charts/friction_domains.png` | File | Bar chart of friction domains |
| `{summary_dir}/charts/principles_invoked.png` | File | Bar chart of principles |

### Error Handling

| Condition | Behavior |
|-----------|----------|
| matplotlib not installed | ImportError (caller should check first) |
| Empty data arrays | Creates chart with "No data" message |

### Dependencies

- Python 3.6+
- `matplotlib` (optional - charts skipped if not installed)

---

## 5. run_weekly_review.sh (Orchestrator)

### Purpose
Orchestrates the full pipeline execution in correct order.

### Input

None (reads from well-known locations).

### Output

| Destination | Type | Description |
|-------------|------|-------------|
| `stdout` | String | Output directory path (last line) |
| `stderr` | String | Progress messages from all stages |

### Execution Order

```bash
1. aggregate.sh          # Creates summary.json, prints OUT_DIR
2. charts.py             # Optional, skipped if matplotlib missing
3. render_md.sh          # Creates review.md
4. render_dashboard.py   # Creates index.html
```

### Error Handling

| Condition | Exit Code | Behavior |
|-----------|-----------|----------|
| aggregate.sh fails | 1 | Exits immediately |
| summary.json missing after aggregate | 1 | Exits with "Missing summary.json" |
| charts.py fails (matplotlib missing) | 0 | Continues with warning |
| render_md.sh fails | 1 | Exits immediately |
| render_dashboard.py fails | 1 | Exits immediately |

### Post-Pipeline Hook

After the orchestrator completes, the skill agent should:
1. Read `summary.json` and `review.md`
2. Fill all 6 placeholders using Edit tool
3. Re-run `render_dashboard.py` to update HTML with synthesized content

---

## Testing Contracts

### Unit Test: aggregate.sh

```bash
# Setup
echo '{"timestamp":"2024-01-15T10:00:00Z","session_id":"test","event_type":"tool_write","payload":{}}' > /tmp/test-events.jsonl

# Test
GLOBAL_STREAM=/tmp/test-events.jsonl ./aggregate.sh

# Verify
jq '.counts.writes' ~/.claude/reviews/week-of-*/summary.json  # Should be 1
```

### Unit Test: render_md.sh

```bash
# Test
./render_md.sh ~/.claude/reviews/week-of-2024-01-15/summary.json

# Verify
grep -c "PLACEHOLDER:" ~/.claude/reviews/week-of-2024-01-15/review.md  # Should be 6
```

### Integration Test: Full Pipeline

```bash
# Run full pipeline
OUT_DIR=$(./run_weekly_review.sh)

# Verify all artifacts exist
[[ -f "$OUT_DIR/summary.json" ]] && echo "✓ summary.json"
[[ -f "$OUT_DIR/review.md" ]] && echo "✓ review.md"
[[ -f "$OUT_DIR/index.html" ]] && echo "✓ index.html"
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-02-25 | Initial contract definition |
