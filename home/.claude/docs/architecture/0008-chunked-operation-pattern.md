---
status: accepted
date: 2026-03-05
deciders: [meaganewaller]
tracking:
  baseline: 878 resource-limit errors (as of 2026-03-05)
  target: 50% reduction by 2026-03-12
  metric: friction subdomain "resource-limit" in skill-friction-log.jsonl
---

# 8. Chunked Operation Pattern for Resource-Safe File Processing

## Status

Accepted

## Context

Resource-limit errors occur when operations exceed context capacity or memory limits. Analysis of friction telemetry shows:

- **878 resource-limit errors** cumulative (as of 2026-03-05)
- Primary causes: reading large log files (especially session `.jsonl`), broad glob patterns, unfiltered grep results
- Existing infrastructure (`large-file-guard.sh`, `bulk-operation-estimator.sh`) provides warnings but doesn't enforce chunking

The gap: **warnings without enforcement allow repeated mistakes**. Developers (human and AI) see warnings but proceed anyway, hitting the same limits.

## Decision

We will implement a **Chunked Operation Pattern** with three enforcement tiers:

### Tier 1: Pre-flight Size Checks (Advisory)

Before any file operation, estimate resource impact:

```
┌──────────────────────────────────────────────────────────────┐
│  OPERATION      │  CHECK                │  THRESHOLD         │
├──────────────────────────────────────────────────────────────┤
│  Read           │  wc -l, stat -f%z     │  >1000 lines/256KB │
│  Glob           │  find -maxdepth sample │  >100 matches     │
│  Grep           │  sampled match count  │  >50 matches       │
│  Write          │  strlen(content)      │  >50KB             │
└──────────────────────────────────────────────────────────────┘
```

Hook: `PreToolUse/large-file-guard.sh`, `PreToolUse/bulk-operation-estimator.sh`

### Tier 2: Blocking Rules (Hard Enforcement)

Some operations should be **blocked**, not warned:

| Path Pattern | Action | Rationale |
|--------------|--------|-----------|
| `.claude/projects/*.jsonl` | Block full read | Session logs cause 99% of resource-limit errors |
| `*.log` > 10MB | Block full read | Log files are append-only; tail is always better |
| Glob `**/*` without extension | Block | Too broad; always requires filtering |

Hook enforcement: Return `{"ok": false, "error": "..."}` to block operation.

### Tier 3: Automatic Chunking (Convenience)

For allowed large operations, provide chunking parameters automatically:

```bash
# File reading - calculate optimal chunk size
eval "$(get_chunk_params "$FILE_PATH")"
# Returns: total_lines=5000 num_chunks=5 chunk_size=1000

# Provide specific offset/limit for each chunk
# Chunk 1: offset=1 limit=1000
# Chunk 2: offset=1001 limit=1000
# ...
```

### Implementation Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `validate-path.sh` | `hooks/common/` | Resource guard functions |
| `large-file-guard.sh` | `hooks/PreToolUse/` | Pre-flight Read checks |
| `bulk-operation-estimator.sh` | `hooks/PreToolUse/` | Pre-flight Glob/Grep checks |
| `large-files` cue | `cues/large-files/` | Strategy documentation |

### Chunking Strategies by File Type

| File Type | Strategy | Example |
|-----------|----------|---------|
| `.jsonl` | Tail + filter | `tail -100 file.jsonl \| jq 'select(.event_type == "X")'` |
| `.log` | Tail + grep | `tail -500 app.log \| grep -i error` |
| `.csv` | Header + ranges | `offset=1 limit=1` then `offset=2 limit=500` |
| Source code | Grep + targeted read | Find function with Grep, Read with offset/limit |
| SQL dumps | Grep for structure | `grep -n 'CREATE TABLE'` to locate sections |

## Consequences

### Positive

- Prevents wasted tool calls that will fail
- Reduces context window pollution from large results
- Session log blocking eliminates 99% of resource-limit errors
- Chunking guidance makes large file access achievable
- Telemetry tracking enables measurement of improvement

### Negative

- Blocking rules may occasionally prevent legitimate operations
- Pre-flight checks add latency (~50-100ms per operation)
- Developers must learn chunking workflow
- False positives on size estimates may cause unnecessary warnings

### Neutral

- Thresholds are configurable via environment variables
- Warnings don't block; only specific rules block
- Pattern applies to all Claude Code sessions via hooks

## Metrics and Tracking

### Baseline (2026-03-05)

```bash
# Count resource-limit friction events
jq -s '[.[] | select(.subdomain == "resource-limit")] | length' \
  ~/.claude/skill-friction-log.jsonl
```

Current: **878 events** (cumulative)

### Target (2026-03-12)

Measure NEW events in the week after implementation:
- 50% reduction from weekly rate: aim for **<50 new events** in week of 2026-03-05 to 2026-03-12
- Stretch goal: **<25 new events** (75% reduction)

### Tracking Query

```bash
# Weekly resource-limit count (new events only)
jq -s --arg start "2026-03-05" --arg end "2026-03-12" '
  [.[] | select(
    .subdomain == "resource-limit" and
    .timestamp >= $start and
    .timestamp < $end
  )] | length
' ~/.claude/skill-friction-log.jsonl
```

## Alternatives Considered

### Alternative A: Block All Large Operations

Block any operation exceeding thresholds, requiring explicit chunking.

**Pros:** Guaranteed prevention of resource-limit errors
**Cons:** Too disruptive; many large operations are valid with offset/limit
**Why rejected:** Blocks legitimate workflows; warning + guidance is sufficient for most cases

### Alternative B: Post-Operation Cleanup

Let operations fail, then suggest chunking after the fact.

**Pros:** No pre-flight latency
**Cons:** Wastes tool calls; error already consumed context
**Why rejected:** Pre-flight prevention is strictly better than post-failure recovery

### Alternative C: Automatic Chunking Wrapper

Intercept Read/Glob/Grep and automatically chunk results.

**Pros:** Transparent to caller; no workflow change needed
**Cons:** Complex implementation; changes tool semantics; hard to debug
**Why rejected:** Too magical; explicit chunking is more predictable

## References

- `home/.claude/hooks/common/validate-path.sh` - Resource guard functions
- `home/.claude/hooks/common/PreToolUse/large-file-guard.sh` - Read pre-flight
- `home/.claude/hooks/common/PreToolUse/bulk-operation-estimator.sh` - Glob/Grep pre-flight
- `home/.claude/cues/large-files/cue.md` - Chunking strategy documentation
- Friction telemetry: `~/.claude/dev-os-events.jsonl` (subdomain: resource-limit)
