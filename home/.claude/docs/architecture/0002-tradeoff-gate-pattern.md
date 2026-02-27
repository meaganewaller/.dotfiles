---
status: accepted
date: 2026-02-27
deciders: [meaganewaller]
---

# 2. Tradeoff Gate Pattern

## Status

Accepted

## Context

Large code changes embed implicit decisions. When a developer changes 100+ lines, they've made choices about what to do and what NOT to do—but these decisions are rarely documented. Six months later, the code answers "what" but not "why" or "what else was considered."

The existing decision journal (`~/.claude/decision-journal/`) captures tradeoffs, but only when someone remembers to write them. Voluntary documentation has low adoption because:

1. The moment of maximum context (during the change) passes quickly
2. There's no prompt or reminder to document
3. The friction of creating an entry feels high relative to the perceived value

We need an enforcement mechanism that prompts for documentation at natural workflow boundaries without blocking urgent work.

## Decision

We will implement a **Tradeoff Gate** pattern that intercepts large changes at two enforcement points and prompts for documentation.

### Enforcement Points

| Point | Trigger | Threshold | Mechanism |
|-------|---------|-----------|-----------|
| Git pre-commit | Staged diff size | 50 lines | Interactive prompt |
| Claude session stop | Edit diff size | 250 lines | Stop hook blocker |

### Git Pre-Commit Gate (`tradeoff-gate`)

When `git commit` stages >50 lines of changes:

1. Display change summary (files, lines added/removed)
2. Prompt with options:
   - `[d]` Document tradeoff (opens editor with template)
   - `[q]` Quick note (one-liner)
   - `[s]` Skip this time
   - `[n]` Not a tradeoff (trivial change)
3. Save documentation to `~/.claude/decision-journal/`

### Claude Session Stop Gate

When Claude Code edits a file with >250 lines changed:

1. `large-diff-escalator.sh` (PostToolUse) creates a pending marker
2. `pending-tradeoff-blocker.sh` (Stop) checks for uncaptured tradeoffs
3. Session cannot end until tradeoffs are documented or markers expire

### Documentation Template

```markdown
# Tradeoff: YYYY-MM-DD

**Branch:** feature-name
**Files changed:** N (+A/-D lines)

## What I chose to do

## What I chose NOT to do

## Why

## Revisit if

## Principles Applied
```

The "Revisit if" section is critical—it transforms a point-in-time decision into a contract with future maintainers.

### Escape Hatches

Enforcement must not be absolute:

| Escape | Use Case |
|--------|----------|
| `SKIP_TRADEOFF=1` | Known trivial change |
| `[n] Not a tradeoff` | Formatting, refactoring |
| `[s] Skip` | Emergency, will document later |
| Marker expiry (1 hour) | Prevents orphaned blocks |
| Non-interactive environments | CI/CD bypasses automatically |

### Threshold Rationale

**50 lines (git):** Low enough to catch meaningful changes, high enough to skip trivial fixes. This is a naive starting point—will adjust based on skip rate data.

**250 lines (Claude):** Higher threshold because AI changes tend to be larger and more mechanical. Catches architectural changes while allowing routine implementation.

Both thresholds are configurable via environment variables (`TRADEOFF_THRESHOLD`, hook configuration).

## Consequences

### Positive

- Captures decisions at moment of maximum context
- Creates searchable institutional memory
- "Revisit if" enables proactive reconsideration
- Tradeoffs feed into weekly review and learning suggestions
- Low-friction options (quick note, skip) prevent blocking flow

### Negative

- Interrupts commit flow (by design, but can feel like friction)
- Threshold is arbitrary—will miss small impactful changes, catch large trivial ones
- Requires discipline to write meaningful content vs. placeholder text
- Two enforcement points means two systems to maintain

### Neutral

- Documentation lives in `~/.claude/decision-journal/` (existing location)
- Integrates with existing telemetry (`dev-os-events.jsonl`)
- Template structure is suggestive, not enforced

## Alternatives Considered

### Alternative A: Advisory Only (No Blocking)

Display a reminder but allow commit/stop regardless.

**Pros:** Zero friction, no escape hatches needed
**Cons:** Easy to ignore; voluntary documentation already failed
**Why rejected:** The whole point is gentle enforcement; advisory doesn't change behavior

### Alternative B: Require Documentation (No Skip)

Block all large changes until documented, no exceptions.

**Pros:** Guaranteed documentation
**Cons:** Creates workarounds (split commits, avoid large changes); hostile to emergencies
**Why rejected:** Overly rigid enforcement breeds resentment and gaming

### Alternative C: Content-Based Triggers

Analyze diff content (architectural keywords, new files, API changes) instead of size.

**Pros:** More precise; catches impactful small changes
**Cons:** Complex to implement; false positives on keyword matches
**Why rejected:** Size is naive but simple; can evolve to content-based later with data

### Alternative D: Post-Commit Documentation

Prompt after commit completes rather than before.

**Pros:** Doesn't block commit flow
**Cons:** Context already fading; easy to dismiss and forget
**Why rejected:** Pre-commit captures context at peak freshness

## References

- `home/.local/bin/tradeoff-gate` - Git pre-commit hook
- `home/.local/bin/tradeoff` - Standalone CLI
- `home/.claude/hooks/PostToolUse/large-diff-escalator.sh` - Creates pending markers
- `home/.claude/hooks/Stop/pending-tradeoff-blocker.sh` - Blocks session stop
- Blog post: `home/.claude/docs/blog-drafts/tradeoff-gate-pattern.md`
