# Tradeoff: 2026-03-09

**Branch:** main
**Files:** home/.claude/skills/common/weekly-review/scripts/aggregate.sh
**Source:** manual-capture

## Decision Summary

Redesigned the weekly review aggregation script to read decisions from both JSONL events and markdown journal files, with multi-strategy project attribution.

## What Was Chosen

A dual-source approach where decisions are read from:
1. `dev-os-events.jsonl` (telemetry events)
2. `~/.claude/decision-journal/*.md` (markdown files - primary source)

Project attribution uses cascading strategies:
1. Session ID mapping (scan project directories for session files)
2. File path encoding matching
3. Date-based correlation with journal entries
4. Content-based inference (keywords like "gusto", "dotfiles")

## Alternatives Considered

- Single source (JSONL only): Simpler but loses decisions captured manually or by subagents
- Single source (journal only): More complete but loses granular telemetry metadata
- Database storage: More query flexibility but adds infrastructure complexity

## Trade-offs

- **Dual source complexity** vs **complete decision capture**: Worth it because auto-capture agent sometimes fails/times out
- **Heuristic project attribution** vs **explicit tagging**: Heuristics work 90%+ of the time without requiring workflow changes
- **Inline Python** vs **separate script**: Keeps aggregation self-contained but makes the shell script harder to read
- **Schema versioning** vs **unversioned output**: Future-proofs consumers but adds maintenance burden

## Principles Applied

- Simplifying For Change: Reading from markdown files allows manual editing without breaking aggregation
- Making Principled Choices: Dual-source handles the reality that auto-capture isn't 100% reliable
- Norming On Conventions: Schema version follows semver for compatibility signaling

## Revisit If

- Auto-capture reliability reaches 99%+ (could simplify to single source)
- Journal files grow to hundreds (may need indexing/caching)
- Project attribution heuristics produce too many false positives
- Need real-time aggregation (current approach is batch-oriented)
