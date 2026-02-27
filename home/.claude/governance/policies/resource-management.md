# Resource Management Policy

This policy governs how AI agents handle large files and batch operations to prevent resource exhaustion.

## Purpose

Resource-limit errors occur when operations exceed context capacity. These errors:

- Interrupt workflow with cryptic failures
- Waste tokens on partial operations that fail
- Create friction that accumulates over sessions

Prevention is more efficient than recovery.

## Scope

This policy applies to:

1. **File reading operations** - Especially files over 1000 lines
2. **Batch operations** - Operations touching more than 10 files
3. **Log file access** - Append-only files that grow indefinitely
4. **Search operations** - Queries that might return large result sets

## Requirements

### ENG-RESOURCE-001: Chunked File Reading

Files over 1000 lines must be read in chunks:

- Use `offset` and `limit` parameters with Read tool
- Default chunk size: 1000 lines (configurable via `RESOURCE_CHUNK_LINES`)
- First read should be small (50-100 lines) to understand structure

**Rationale**: Large files can overflow context windows. Chunked reading ensures full access while maintaining stability.

### ENG-RESOURCE-002: Batch Operations

Operations touching more than 10 files should use batching:

- Group files into batches of 5-10
- Complete and verify each batch before proceeding
- Use progress indicators for visibility

**Rationale**: Batch processing prevents memory exhaustion and provides natural checkpoints for error recovery.

### ENG-RESOURCE-003: Log File Access

Log files (`.jsonl`, `.log`, append-only) require special handling:

- Never read entire log files
- Read from end using `tail` for recent entries
- Use time-based or line-count filtering
- Prefer structured queries (jq for JSON logs)

**Rationale**: Log files grow indefinitely and have no natural size limit.

### ENG-RESOURCE-004: Search Result Limits

Search operations should limit results:

- Use `head_limit` parameter with Grep/Glob
- Process results in batches if count is high
- Narrow search scope before widening

**Rationale**: Unbounded search results can overwhelm processing capacity.

## Implementation

### Pre-Read Check

Before reading unfamiliar files:

```bash
wc -l /path/to/file      # Check line count
head -50 /path/to/file   # Preview structure
```

### Chunked Read Pattern

```
# First chunk
Read file_path="/path" offset=1 limit=1000

# Subsequent chunks
Read file_path="/path" offset=1001 limit=1000
```

### Batch Processing Pattern

```
# Process in groups
files = [...list of files...]
for batch in chunks(files, 10):
    process(batch)
    verify(batch)
```

## Metrics

- **Target**: Zero resource-limit errors per week
- **Tracking**: `resource-limit` subdomain in friction log
- **Review**: Weekly review includes resource-limit analysis

## References

- Helper functions in `~/.claude/hooks/common/validate-path.sh`
- Large file guard hook: `~/.claude/hooks/common/PreToolUse/large-file-guard.sh`
- Large files cue: `~/.claude/cues/large-files/cue.md`
