---
title: The Tradeoff Gate Pattern
date: 2026-03-02
layout: post
tags: [developer-tooling, decision-records, claude-code, workflow-automation, productivity]
---

# The Tradeoff Gate: Enforcing Decision Documentation at Commit Time

Every large code change embeds decisions. Most of those decisions are never written down. The Tradeoff Gate pattern changes that by creating a lightweight enforcement mechanism that prompts for documentation at the moment when context is freshest.

## Why Tradeoffs Matter More Than Decisions

When we talk about "documenting decisions," we usually focus on what we chose to do. But the real leverage is in documenting what we chose NOT to do.

Consider a commit that refactors authentication from sessions to JWTs. The decision to use JWTs is visible in the code. What's invisible:

- Why not continue with sessions? (Scaling concerns with shared state)
- Why not use opaque tokens with a token introspection endpoint? (Latency budget)
- Why 15-minute expiry instead of 1 hour? (Security posture for this app)
- When should we revisit this? (If we add refresh token rotation)

Six months later, someone asks "why JWTs?" The code answers "because JWTs." The tradeoff documentation answers "because we valued horizontal scaling over session revocation simplicity, and here's when that tradeoff should be reconsidered."

## The Pattern

The Tradeoff Gate intercepts large changes and prompts for documentation before allowing completion. It works at two enforcement points:

**1. Git pre-commit hook** for human commits:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Large Change Detected: 127 lines (+89/-38) across 4 files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document the tradeoff (30 seconds):
  What did you choose NOT to do, and why?

  Options:
    [d] Document tradeoff (opens editor)
    [q] Quick note (one-liner)
    [s] Skip this time
    [n] Not a tradeoff (trivial change)
```

**2. AI session stop hook** for Claude Code:

When Claude makes a change over 250 lines, it creates a "pending tradeoff" marker and displays an advisory message encouraging inline discussion. At session stop, an agent hook automatically extracts tradeoff reasoning from the conversation:

```
📝 LARGE CHANGE: src/auth/jwt.ts (312 lines)

Tradeoffs will be auto-captured when the session ends. To enrich the capture, consider noting:

**Tradeoffs:** X vs Y decisions you made
**Options Considered:** Alternatives you evaluated
```

The key insight: inline discussion during the session gives the auto-capture agent richer context to work with. You don't have to formally document—just think out loud about your choices.

## The Template

Both gates use the same documentation structure:

```markdown
# Tradeoff: 2026-02-27

**Branch:** feature/jwt-auth
**Files changed:** 4 (+89/-38 lines)

## What I chose to do

Migrated session-based auth to stateless JWTs with 15-minute expiry.

## What I chose NOT to do

- Session-based auth with Redis backing (horizontal scaling complexity)
- Opaque tokens with introspection endpoint (latency budget exceeded)
- Longer JWT expiry (security posture for financial data)

## Why

Horizontal scaling is a hard requirement for Q3. Sessions require shared state.
JWTs eliminate that dependency at the cost of immediate revocation capability.

## Revisit if

- We need immediate session revocation (add token denylist)
- Latency budget increases (consider introspection)
- Refresh token rotation is implemented
```

The key insight is the "Revisit if" section. This turns a point-in-time decision into a living contract with future maintainers.

## Implementation

> **Note:** This is a naive first implementation. The current triggers (50 lines for commits, 250 lines for AI edits) are starting points, not gospel. Line count is a blunt instrument—it catches large refactors that are purely mechanical and misses small changes with significant architectural implications. As the system collects data on which prompts get skipped vs. documented, the triggers will evolve. The pattern matters more than the specific thresholds.

### Git Pre-Commit Hook

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit or linked from ~/.config/git/hooks/

THRESHOLD="${TRADEOFF_THRESHOLD:-50}"
TOTAL=$(git diff --cached --numstat | awk '{s+=$1+$2} END {print s+0}')

if (( TOTAL >= THRESHOLD )); then
  # Prompt for documentation (see full implementation)
fi
```

The threshold is configurable via `TRADEOFF_THRESHOLD`. Default is 50 lines, which catches meaningful changes without creating friction for small fixes.

### Claude Code Stop Hook

For AI-assisted development, the enforcement happens at session boundaries through auto-capture:

1. **PostToolUse hook** detects large changes (>250 lines), creates a pending marker, and displays an advisory encouraging inline tradeoff discussion
2. **Context prep hook** prepares pending tradeoff information for the agent
3. **Agent hook** analyzes the session's conversation for tradeoff reasoning, extracts structured data, and emits a `decision_tradeoff` event

This creates a closed loop without blocking: tradeoffs are captured automatically from the conversation context. Inline discussion during the session (explaining your choices, mentioning alternatives considered) enriches what the agent can extract.

The agent distinguishes meaningful tradeoffs from mechanical changes—a large formatting change won't trigger a documentation event, but a refactor with architectural implications will.

### Escape Hatches

No enforcement mechanism should be absolute. The gates provide escapes:

**Git:**
- `SKIP_TRADEOFF=1 git commit` bypasses the pre-commit hook
- `[n] Not a tradeoff` marks changes as intentionally undocumented (refactoring, formatting)

**Claude Code:**
- Markers auto-expire after 1 hour to prevent stale state
- The agent silently skips mechanical changes with no meaningful reasoning
- Auto-capture never blocks—it extracts what it can and moves on

The bypass exists because sometimes you know better than the tooling. But the default path encourages documentation.

## Adopting the Pattern

To add the Tradeoff Gate to your workflow:

**Minimal version (git only):**

```bash
# In your pre-commit hook
LINES=$(git diff --cached --numstat | awk '{s+=$1+$2} END {print s+0}')
if (( LINES > 50 )); then
  echo "Large change detected ($LINES lines)"
  read -p "Document tradeoff? [y/n]: " choice
  if [[ "$choice" == "y" ]]; then
    $EDITOR ~/.decisions/$(date +%Y-%m-%d)-tradeoff.md
  fi
fi
```

**Full version:**

1. Add `tradeoff-gate` to your git hooks
2. Add `tradeoff` CLI to your PATH for ad-hoc documentation
3. If using Claude Code, add the PostToolUse and Stop hooks
4. Review tradeoffs weekly (they feed into retrospectives)

## The Compound Effect

Individual tradeoff documents have modest value. The compound effect is substantial:

- **Onboarding**: New team members read decision history, not just code
- **Debugging**: "Why does this work this way?" has an answer
- **Refactoring**: "Revisit if" conditions trigger intentional reconsideration
- **Reviews**: Weekly tradeoff review surfaces patterns in decision-making
- **AI context**: Tradeoffs feed back into AI assistant prompts for continuity

The gate creates a forcing function. The documentation creates institutional memory. Together, they transform implicit decisions into explicit, searchable, actionable knowledge.

## Conclusion

Large changes deserve documentation. The Tradeoff Gate makes documentation the path of least resistance by intercepting changes at commit time and session boundaries. It's lightweight enough to not impede flow, structured enough to capture useful information, and escapable when you need to move fast.

The pattern answers a simple question: "How do you ensure decisions get documented?"

You make documentation the default, provide good templates, and create gentle enforcement at natural workflow boundaries. Then you watch what actually happens and adjust the triggers based on real usage.

---

*The full implementation is available in my [dotfiles repository](https://github.com/meaganewaller/.dotfiles). The relevant files are `home/.local/bin/tradeoff-gate` (git hook), `home/.local/bin/tradeoff` (CLI), `home/.claude/hooks/PostToolUse/large-diff-escalator.sh` (marker creation), and `home/.claude/hooks/Stop/tradeoff-context-prep.sh` (context preparation for auto-capture).*