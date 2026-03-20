---
status: accepted
date: 2026-03-20
deciders: [meaganewaller]
tracking:
  baseline: 395 resource-limit errors (week of 2026-03-16)
  target: <100 resource-limit errors by end of week
  metric: friction subdomain "resource-limit" in skill-friction-log.jsonl
---

# 10. Pre-flight Size Estimation Pattern

## Status

Accepted

## Context

Resource-limit errors remain a significant source of friction despite existing warnings:

- **395 resource-limit errors** in the week of 2026-03-16
- **408 of 420** recent errors were from session log reads (97%)
- Existing `large-file-guard.sh` provided warnings but didn't effectively prevent errors

The root cause: **PreToolUse hooks can add advisory context but cannot actually block tool execution**. The `{"ok": false}` output is ignored by Claude Code for PreToolUse events (unlike Stop events where it works).

## Decision

We will implement a **Pre-flight Size Estimation Pattern** with three components:

### 1. `size_estimate()` Utility Function

A comprehensive function in `validate-path.sh` that returns JSON with:

```bash
size_estimate "/path/to/file"
# Returns:
{
  "exists": true,
  "path": "/path/to/file",
  "size_kb": 753,
  "lines": 15000,
  "file_type": "session-log",
  "should_block": true,
  "block_reason": "Session logs are blocked...",
  "recommendation": "Use: grep 'pattern' ... | tail -20",
  "chunk_suggestion": "offset=14500 limit=500",
  "chunks": {
    "recommended_size": 500,
    "total_chunks": 30
  }
}
```

File types recognized:
- `session-log` - Always blocked
- `log-file` - Blocked if >10MB, warned otherwise
- `csv` - Header-first reading strategy
- `database-dump` - Grep-based section finding
- `source-code` - Grep for functions, then chunked read
- `text` - Chunked reading

### 2. `should_block_read()` Quick Check

Fast boolean check for blocking decisions:

```bash
if should_block_read "/path/to/file"; then
  echo "Use alternative: $(safe_read_cmd "$path")"
fi
```

### 3. Enhanced `large-file-guard.sh` Hook

Updated PreToolUse hook that:
- Uses `size_estimate()` for comprehensive analysis
- Emits telemetry events (`preflight_block`, `preflight_warn`) for tracking
- Provides prominent markdown-formatted warnings
- Includes specific chunked reading recommendations

### Blocking Rules

| Pattern | Action | Reason |
|---------|--------|--------|
| `.claude/projects/*.jsonl` | Block | Session logs cause 97% of errors |
| `*.log` or `*.jsonl` > 10MB | Block | Tail is always better |
| Any file > 256KB or > 1000 lines | Warn | Provide chunked reading guide |

## Consequences

### Positive

- **Consistent API**: `size_estimate()` provides uniform interface for size checking
- **Telemetry**: Block/warn events tracked for measuring effectiveness
- **File-type awareness**: Recommendations tailored to file type
- **Reusable utilities**: `should_block_read()` and `safe_read_cmd()` available to other hooks

### Negative

- **Cannot truly block**: PreToolUse hooks only advise; Read may still be attempted
- **Additional overhead**: Size checks run before every Read operation (mitigated by early exit for small files)

### Neutral

- **Supplements ADR-0008**: This implements the "Pre-flight Size Checks" tier of the Chunked Operation Pattern
- **Relies on compliance**: Effectiveness depends on Claude following advisory recommendations

## Measurement

Track reduction in resource-limit friction:

```bash
# Count resource-limit errors in last 7 days
tail -5000 ~/.claude/skill-friction-log.jsonl | \
  jq -c 'select(.subdomain == "resource-limit")' | \
  jq -s 'length'

# Track blocking telemetry
grep '"preflight_block"' ~/.claude/dev-os-events.jsonl | \
  jq -s 'group_by(.payload.file_type) | map({type: .[0].payload.file_type, count: length})'
```

## Related

- ADR-0008: Chunked Operation Pattern (parent pattern)
- `home/.claude/hooks/common/validate-path.sh` - Utility functions
- `home/.claude/hooks/common/PreToolUse/large-file-guard.sh` - Hook implementation
