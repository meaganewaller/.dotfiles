---
title: "Dev OS Week 3: Persistence, Principles, and Pacing"
date: 2026-03-09
layout: post
tags: [claude-code, developer-tools, telemetry, decisions, productivity, hooks, skills]
---

# Dev OS Week 3: Persistence, Principles, and Pacing

Three weeks into building Dev OS, I've hit a satisfying phase: the system is now mature enough that new features are refinements instead of foundational work. Last week was dense—45 commits, 6 new hooks, 4 new skills, 5 new cues. The work clustered around three themes: making decisions durable, keeping principles active, and pacing long sessions.

## The Decision Persistence Problem

Dev OS already captured tradeoff documentation through agent hooks. When a session made large code changes, an agent would extract reasoning from the conversation and emit a `decision_tradeoff` event to `dev-os-events.jsonl`.

This worked for telemetry—the weekly review could count decisions and extract principles. But there was a problem: **events aren't version-controlled**.

The telemetry stream is ephemeral. It lives in `~/.claude/`, gets analyzed weekly, and eventually ages out. If I wanted to find why I made a particular architectural choice six months ago, I'd be digging through JSONL files with timestamps I don't remember.

Meanwhile, the `decision-journal/` directory existed specifically for version-controlled decisions. But the auto-capture system didn't write to it—only the manual git pre-commit hook did.

The fix was straightforward: update both agent hooks (Stop and SubagentStop) to write markdown files as the **primary output**, with events as secondary telemetry.

```markdown
# Tradeoff: 2026-03-09

**Branch:** feature-branch
**Files:** config/database.yml, lib/connection.rb
**Source:** auto-capture

## Decision Summary

Chose connection pooling over per-request connections...

## Alternatives Considered

- Per-request connections (rejected: overhead)
- Persistent connections (rejected: stale state)

## Trade-offs

- Pooling adds complexity but reduces latency
- Must handle connection exhaustion gracefully

## Principles Applied

- Performance over simplicity for hot paths
- Fail-fast on resource exhaustion

## Revisit If

- Connection limits change significantly
- Moving to serverless architecture
```

Now decisions live in git. They show up in diffs. They can be searched with grep. The weekly review aggregates from both sources—journal files for the structured content, events for the timestamps and attribution.

### Integrating with Weekly Review

The aggregation script needed updates to read the journal directly:

```python
# Read decisions from journal files for this week
for jf in journal_dir.glob("*.md"):
    date_prefix = extract_date(jf.name)
    if date_prefix < week_start or date_prefix > week_end:
        continue

    content = jf.read_text()
    journal_decisions.append({
        "file": jf.name,
        "date": date_prefix,
        "summary": extract_summary(content),
        "tradeoffs": extract_list(content, "Trade-offs"),
        "principles": extract_list(content, "Principles Applied"),
        "source": extract_source(content)
    })
```

The summary now includes:
- `decisions_from_journal`: Primary count (version controlled)
- `decisions_from_events`: Secondary count (telemetry only)
- `capture_sources`: Distribution of auto-capture vs manual

This closes a loop I'd been circling: **decisions should be as durable as code**. The telemetry stream is for analysis; the journal is for history.

## The Resource Limit Problem

Friction telemetry revealed an embarrassing pattern: **878 resource-limit errors** cumulative. The same mistake, hundreds of times.

The culprits were predictable:
- Reading session log files without offset/limit
- Glob patterns like `**/*` without extension filters
- Grep results that returned thousands of matches

I had hooks that warned about this. `large-file-guard.sh` would inject a message about chunking strategies. But warnings are easy to ignore—especially for an AI that's confident it can handle the operation.

### ADR-0008: Chunked Operation Pattern

The solution has three tiers:

**Tier 1: Pre-flight Checks (Advisory)**

Before Read/Glob/Grep, estimate the resource impact:

| Operation | Check | Threshold |
|-----------|-------|-----------|
| Read | Line count | >1000 lines |
| Glob | Match sample | >100 files |
| Grep | Match count | >50 results |

Hooks inject warnings with specific remediation steps.

**Tier 2: Blocking Rules (Enforcement)**

Some operations should fail immediately:

- `.claude/projects/*.jsonl` - Session logs caused 99% of resource-limit errors. Block them entirely; use `tail` instead.
- Glob `**/*` without extension - Too broad. Always fails. Require a filter.
- Log files over 10MB - Always use `tail`. No exceptions.

Blocking rules return `{"ok": false, "error": "..."}` which halts the operation before it starts.

**Tier 3: Automatic Chunking (Convenience)**

For allowed large operations, calculate chunking parameters:

```bash
# Returns: total_lines=5000 num_chunks=5 chunk_size=1000
eval "$(get_chunk_params "$FILE_PATH")"
```

This makes the "right way" as easy as the "wrong way."

### Tracking the Improvement

The ADR includes explicit metrics:

- **Baseline**: 878 cumulative resource-limit errors
- **Target**: 50% reduction in *new* errors (week of 2026-03-05 to 2026-03-12)
- **Stretch**: 75% reduction (<25 new errors)

The tracking query:

```bash
jq -s --arg start "2026-03-05" '
  [.[] | select(.subdomain == "resource-limit" and .timestamp >= $start)]
  | length
' ~/.claude/skill-friction-log.jsonl
```

This is something I've learned from building Dev OS: **changes without metrics are hopes**. The friction taxonomy makes it possible to measure whether interventions actually work.

## Elevating Patterns to Skills

Last week's TemplateContext pattern (ADR-0007) solved a real problem: SimpleCov struggles to instrument ERB branches, so template conditionals showed 0% coverage even when tested.

The solution—extract conditionals to a PORO—worked well enough that I wanted it reusable. Not just documented in an ADR, but **available as a skill** that could guide future generator work.

The skill lives in `~/.claude/skills/common/template-context/SKILL.md`:

```yaml
---
name: template-context
description: This skill should be used when asking about "testing Rails
  generators", "ERB coverage", "template branch coverage"...
---

# TemplateContext Pattern

Extract ERB template conditionals into a testable Plain Old Ruby Object...

## When to Apply

- Template has 3+ conditional branches
- Coverage metrics are a project requirement
- You need to unit test template logic in isolation

## Implementation Steps

### Step 1: Identify Template Conditionals
### Step 2: Create the Context Class
### Step 3: Update the Template
### Step 4: Write Unit Tests
### Step 5: Verify Coverage
```

The skill cross-references the ADR, but adds implementation guidance—step-by-step instructions, code templates, a verification checklist. The ADR answers "why this pattern?" The skill answers "how do I use it?"

This creates a two-layer system:
- **ADRs** capture decisions with context and alternatives (for understanding)
- **Skills** provide actionable guidance (for doing)

The pattern generalizes: any decision significant enough for an ADR probably deserves a skill if it's something you'll apply repeatedly.

## Session Duration Monitoring

Long sessions correlate with friction. This isn't surprising—fatigue sets in, context accumulates, and both human and AI start making sloppier decisions. But correlation isn't useful without intervention.

ADR-0006 introduced session archetypes with tailored guidance:

| Duration | Archetype | Intervention |
|----------|-----------|--------------|
| 30 min | Flow | "Consider creating a task list" |
| 120 min | Marathon | "Consider a commit checkpoint and break" |
| 240 min | Ultramarathon | Stronger friction warning |

The `session-duration-monitor.sh` hook tracks elapsed time and emits periodic events. At each threshold, it injects contextual suggestions—not blocking, but present enough to prompt reflection.

The pre-compact snapshot now includes session metrics too. When context compaction happens (a sign of long, complex sessions), the system captures duration and archetype. This creates a dataset for analyzing the relationship between session length and error rates.

Early observation: sessions over 2 hours have 3x the friction rate of sessions under 30 minutes. The causality could run either direction—long sessions might cause friction, or friction might cause sessions to drag on. Either way, the intervention is the same: take a break, commit your progress, start fresh.

## Principle Reinforcement

Dev OS already had principles documented in `~/.claude/principles/`. But documentation that sits in files doesn't affect behavior. I noticed a pattern: principles would get invoked once in a conversation, then forgotten.

The fix is a two-hook system:

**`principle-activator.sh`** (PostToolUse): Scans tool output for principle keywords. When it sees "separation of concerns" or "fail-fast" or similar, it marks that principle as "active" for the session.

**`principle-reinforcer.sh`** (PreToolUse): Before Write/Edit operations, checks for active principles. If found, it re-surfaces them with a gentle reminder: "Active principle: separation of concerns. Does this change align?"

The reminders are rate-limited (5-minute cooldown) to avoid noise. And they're tied to specific principles actually mentioned in the session—not generic advice, but reinforcement of decisions already made.

This addresses what I call the "breadth-not-depth" problem: covering many ideas shallowly instead of applying a few ideas consistently. The system remembers what I said I cared about, then asks if I'm still caring about it.

## Loop Detection

Sometimes the AI gets stuck. It tries something, it fails, it tries the same thing again. And again. Before loop detection, these cycles could burn through tool calls without progress.

`loop-detector.sh` watches for patterns:
- Same file edited multiple times without intervening reads
- Error rate exceeding 50% over recent operations
- No new files touched in 10+ operations

When detected, it injects a prompt: "Possible loop detected. Consider: stepping back to understand the root cause, trying a different approach, or asking for clarification."

The goal isn't to block—loops sometimes resolve themselves—but to create a moment of reflection. Often that's enough to break the cycle.

## Expanding the Skill Library

Three new skills joined the catalog:

**`code-review`**: Structured review across dimensions (correctness, security, performance, maintainability). Provides a checklist approach rather than unstructured feedback.

**`debug-session`**: Systematic debugging with hypothesis-test methodology. Forces explicit hypotheses before diving into code, which prevents the "randomly changing things" anti-pattern.

**`standup`**: Generates daily standup content from dev-os-events. The aggregation script pulls yesterday's activity and formats it for team communication. No more forgetting what you worked on.

The standup skill is particularly interesting because it closes a loop: telemetry that was captured for analysis now produces direct output. The same events that feed weekly reviews also generate daily standups.

## Expanding the Cue Library

Four new cues provide context-specific guidance:

**`testing`**: Triggers on `*_spec.rb`, `*.test.ts`, and similar patterns. Injects testing best practices—describe/it structure, assertion clarity, avoiding test interdependence.

**`security`**: Triggers on auth, crypto, and sensitive data patterns. OWASP-aligned guidance for common vulnerability categories.

**`debugging`**: Triggers on "bug", "error", "broken" keywords. Promotes systematic debugging over random changes.

**`file-verification`**: A meta-cue for file operations. Promotes "verify-then-act"—check that paths exist before operating on them. This addresses the chronic file-not-found errors in friction telemetry.

The file-verification cue is unusual because it's about the *how* of tool usage, not the *what* of code. It's teaching better habits for working with Claude Code itself.

## Model-First Development

Telemetry showed a pattern: low domain modeling, high reversals. I was jumping into implementation without thinking through the domain—then having to undo work when the model didn't fit.

The `model-first` cue triggers before implementation tasks. It prompts:

> Before implementing, consider: What are the nouns (entities)? What are the verbs (commands/events)? What invariants must hold? What existing patterns should you follow?

The accompanying principle document (`model-first-development.md`) expands on modeling techniques—entity identification, boundary definition, state machine thinking.

This is preventive rather than reactive. Instead of catching reversals after they happen, it encourages the thinking that prevents them.

## What This Enables

These changes are individually small but collectively significant:

**Decisions are searchable history**. Six months from now, I can `grep -r "connection pool" ~/.claude/decision-journal/` and find exactly why that choice was made, what alternatives existed, and when to reconsider.

**Resource errors are prevented, not just warned about**. The blocking rules for session logs alone should eliminate the majority of resource-limit friction.

**Patterns compound**. The TemplateContext skill means the next Rails generator I build starts with a known solution for coverage gaps. I'm not re-deriving the pattern—I'm applying it.

**The weekly review tells a richer story**. With journal decisions included, the review shows not just what I built, but why I built it the way I did.

**Principles persist across a session**. When I invoke "separation of concerns" early in a conversation, the system reminds me of it before later edits. Consistency without perfect memory.

**Sessions have natural checkpoints**. Duration monitoring creates gentle friction at marathon boundaries. The result: more commits, more breaks, fresher context.

**Daily standups write themselves**. The same telemetry that feeds weekly reviews now generates daily summaries. No more forgetting what I worked on yesterday.

## The Meta-Pattern

Three weeks in, a meta-pattern is emerging: **Dev OS is infrastructure for making good decisions stick**.

Friction detection catches mistakes as they happen. Cues inject guidance at decision points. The decision journal captures reasoning. The weekly review surfaces patterns. Each component addresses a different failure mode:

| Failure Mode | Component | Mechanism |
|--------------|-----------|-----------|
| Repeating mistakes | Friction detection | Surface patterns, prompt practice |
| Forgetting conventions | Cues | Inject guidance at trigger points |
| Losing context | Decision journal | Persist reasoning with code |
| Missing trends | Weekly review | Aggregate and synthesize |
| Ignoring warnings | Blocking rules | Enforce, don't suggest |
| Breadth over depth | Principle reinforcement | Re-surface active principles |
| Session fatigue | Duration monitoring | Checkpoint prompts at thresholds |
| Getting stuck | Loop detection | Pattern recognition, reflection prompts |
| Jumping to code | Model-first cue | Prompt domain thinking first |

The system doesn't make me smarter. It makes my existing knowledge and past decisions **accessible and applicable** in the moment they're relevant.

That's the real value of building this infrastructure: not automation, but **amplification**. The AI becomes more useful because it has better context. I become more consistent because the system remembers what I forget.

## What's Next

The chunked operation pattern has explicit success metrics. If resource-limit errors don't drop by 50%, the intervention failed and I need to understand why. Session duration monitoring will show whether checkpoint prompts actually reduce marathon sessions. That feedback loop—implement, measure, adjust—is becoming the heartbeat of Dev OS development.

Beyond metrics, I'm noticing gaps that point toward future work:

- **Cross-project patterns**: The TemplateContext skill is useful, but only for Rails generators. What about patterns that span technologies?
- **Decision chains**: Sometimes decisions build on each other. ADR-0007 (TemplateContext) enabled ADR-0008 (Chunked Operations) by establishing the pattern of extracting logic for testability. How do I capture that lineage?
- **Skill retirement**: If a skill stops being used, is it still valuable? Telemetry shows skill invocations, but not whether invocations were helpful.
- **Principle effectiveness**: The reinforcement system tracks when principles are surfaced, but not whether they changed behavior. Did that "separation of concerns" reminder actually affect the edit?

These are the right kinds of questions—emerging from observed system behavior, not theoretical appeal. The system tells me what it needs next.

## The Week in Numbers

| Metric | Count |
|--------|-------|
| Commits | 45 |
| New hooks | 6 (loop-detector, session-duration-monitor, principle-activator, principle-reinforcer, bulk-operation-estimator, pre-compact-snapshot enhancements) |
| New skills | 4 (code-review, debug-session, standup, template-context) |
| New cues | 5 (testing, security, debugging, file-verification, model-first) |
| ADRs written | 3 (0006 session duration, 0007 TemplateContext, 0008 chunked operations) |
| Lines of hook code | ~800 |

It was a productive week.

---

*The full implementation lives in my [dotfiles](https://github.com/meaganewaller/.dotfiles/tree/main/home/.claude). ADRs 0006, 0007, and 0008 document the key decisions. The weekly review now aggregates 17 skills and 9 cues.*
