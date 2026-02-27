# Tradeoff: 2026-02-27

**Branch:** main (dotfiles)
**Context:** Implementing chunked file reading for large files

## What I chose to do

- 1000-line threshold for "large file" detection (configurable via `RESOURCE_LARGE_FILE_THRESHOLD`)
- PreToolUse hook (`large-file-guard.sh`) that warns but doesn't block
- File-type-specific advice (log files → tail, CSV → header first, SQL → grep for tables)
- Utility functions in `validate-path.sh` for reuse across hooks

## What I chose NOT to do

- **Hard blocking on large file reads** - Would break legitimate use cases; advisory is sufficient
- **Always chunking regardless of size** - Adds friction for small files; threshold is reasonable default
- **ML-based file analysis** - Overkill; file extension heuristics work well enough
- **Modifying Read tool behavior directly** - Hook approach is less invasive, more observable

## Why

Advisory approach respects user agency while providing guardrails. The hook creates observability (can track how often it fires) without blocking workflow. File-type advice reduces cognitive load at decision point.

## Revisit if

- Resource-limit errors persist despite warnings (may need harder enforcement)
- Threshold proves wrong (track skip rate in telemetry)
- New file types need specific handling

## Principles Applied

- **Simplifying For Change:** Small, focused hook; utilities extracted for reuse
- **Norming On Conventions:** Follows existing hook patterns (source validate-path.sh, hook_register)
- **Making Principled Choices:** Advisory over blocking; configurable thresholds
