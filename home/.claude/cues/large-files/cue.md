---
# Triggers when reading large files or batch operations
pattern: large file|read.*lines|offset|limit|chunk|batch|many files|multiple files|resource.?limit|exceeds.*size|file.*too large
files: \.log$|\.jsonl$|\.csv$|\.sql$|dump
scope: agent, subagent
description: Large file operations, chunked reading, batch processing, resource limits
vocabulary: chunk chunked batch batched offset limit lines large huge massive scroll paginate resource-limit
provenance:
  policy:
    - uri: home/.claude/governance/policies/resource-management.md
      type: governance-doc
  controls:
    - id: ENG-RESOURCE-001
      name: Chunked File Reading
      justifications:
        - Files over 1000 lines should use offset/limit parameters
        - Prevents context overflow and resource-limit errors
    - id: ENG-RESOURCE-002
      name: Batch Operations
      justifications:
        - Operations touching >10 files should use batching
        - Progress indicators help track long operations
  verified: 2026-02-27
  rationale: >
    Resource-limit errors occur when operations exceed context capacity.
    Chunked reads and batch processing prevent these errors while maintaining
    full access to file contents.
---

# Large File Operations

When working with large files (>1000 lines) or multiple files (>10):

## Reading Large Files

Use the Read tool's `offset` and `limit` parameters:

```
Read file_path="/path/to/file" offset=1 limit=500     # Lines 1-500
Read file_path="/path/to/file" offset=501 limit=500  # Lines 501-1000
```

**Strategy:**
1. First read with `limit=100` to understand structure
2. Use Grep to find specific sections
3. Read targeted ranges with `offset` and `limit`

## Batch Operations

When modifying multiple files:
- Group related changes into batches of 5-10 files
- Complete one batch before starting the next
- Verify each batch before proceeding

## Checking File Size

Before reading an unfamiliar file:
```bash
wc -l /path/to/file  # Get line count
head -50 /path/to/file  # Preview structure
```

## Log Files

For `.jsonl`, `.log`, and similar append-only files:
- Read from the end: `tail -100 file.jsonl`
- Use time-based filtering with `jq` for JSON logs
- Never read entire log files into context

## Related Principles

See `~/.claude/principles/efficiency-principles.md` for:
- Resource-aware operations
- Context window economy
- Progressive loading strategies

**Key heuristic:** If you've hit "exceeds maximum size" once, don't retry without offset/limit.
