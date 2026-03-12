---
title: "Building Dev OS: Engineering Telemetry for AI-Assisted Development"
date: 2026-02-27
tags: [claude-code, developer-tools, telemetry, productivity]
layout: post
description: How I built a support system for Claude.
---

# Building Dev OS

There’s a very online take on AI coding assistants that goes something like this:

> Just describe the feature and let the robot do the work.

I don’t buy it.

AI is powerful. But “describe it and ship it” is a fantasy unless your codebase is trivial or you don’t care how it ages. Models are good at patterns. They are not good at memory, long-term context, or caring about your team’s weird little conventions that absolutely matter in production.

So instead of trying to make Claude do everything, I started building something else.

I built **Dev OS**.

Not an AI replacement or autopilot, something more like a support system.

## The Actual Problem

Claude Code is capable. But every session starts cold.

It doesn’t know that:

* I’ve hit `file not found` twelve times this week.
* I always forget to document tradeoffs on large refactors.
* I will absolutely try to commit without running tests if I’m in flow.

Each session is amnesia.

And when you combine amnesia with high confidence, you get subtle, repeatable mistakes.

The agent lacks context.

## The Rule: Build What Annoys You

I didn’t sit down and architect Dev OS.

I got annoyed.

I kept ending sessions with failing tests. Then I’d restart, rehydrate context, re-run everything. It was stupid.

So I wrote a hook:

> On `Stop`, if the last test failed → block the session from ending.

That’s it. Fifteen lines of bash.

It worked immediately.

And that’s when it clicked:
Instead of asking Claude to be “smarter,” I could build infrastructure around it in the form of guardrails and memory.

## Phase 1: Friction Detection

If something fails, I want to know *why* and whether it’s a pattern.

So I wrote `skill-gap-detector.sh`.

Every tool failure gets classified:

```
Primary Domains:
├── syntax
├── type
├── dependency
├── permission
├── state
├── config
├── testing
└── build
```

Each event logs to:

```
~/.claude/skill-friction-log.jsonl
```

Then at `SessionStart`, another hook runs:

If a domain fires 3+ times in 24 hours, surface it.

Example:

```
Repeated friction in [state]: 15 hits.
Subdomains: file-not-found(10), resource-limit(5)
Hint: Use offset/limit for large files.
```

I learned something mildly humiliating:

Resource limits were ~40% of my failures.

Not because I don’t understand chunking.

Because I forget when I’m moving fast.

Telemetry > vibes.

---

## Phase 2: Impact Tracking

Friction tells you where you struggle.

But what about where you ship?

I added `impact-extractor.sh`:

* Logs file writes
* Classifies change type (refactor, bugfix, architecture)
* Infers risk level
* Emits events to a unified stream:

```
~/.claude/dev-os-events.jsonl
```

Then I layered in more detectors:

* Large diffs (>250 lines)
* Reversal detection (undoing recent work)
* Dependency change tracking

Now I don’t just know that I’m coding.

I know *what kind* of coding I’m doing.

---

## Phase 3: Weekly Review

Once you have events, you need synthesis.

So I built `/weekly-review`.

It aggregates:

* Execution metrics
* Friction rates
* Discipline flags
* Per-repo activity
* Cue engagement

It generates:

* Markdown report
* Charts
* HTML dashboard
* AI-synthesized insight

And this is the part that matters:

Claude looks at the telemetry and tells me patterns I might miss.

Example synthesis:

> High throughput week. Friction concentrated in environmental instability, not capability gaps. Precision move: make hook scripts idempotent.

Now we're getting real directional feedback.

## Phase 4: Cues (Compiled Policy)

Observation tells you what already happened. I wanted something that shapes behavior _before_ the mistake. So I built cues.

A cue is a small, declarative policy that gets injected into Claude's context when certain triggers match. Think of it as just-in-time guidance.

For example, my commit cue:

```markdown
# Commit cue

- Use conventional commits: `type(scope): message`
- Keep subject under 72 characters
- Ensure tests pass before pushing
```

Cues fire based on:

- Regex matches in prompts
- Bash command detection (`git commit`, etc.)
- File path patterns
- Semantic similarity fallback (using gzip-based normalized compression distance)

Yes, I implemented compression-distance semantic matching (and no, it's NOT overkill!).

Regex catches literal words.
Semantic matching catches intent.

Cues are essentially compiled governance:

Human-readable policy → compressed, context-efficient AI directive.

## Engagement Tracking (Because Otherwise It’s Just Vibes)

Every time a cue fires, it logs an event.

That means I can see:

* Which cues trigger most often
* Which ones never trigger
* Which ones trigger frequently but don't seem to change behavior

If a cue fires constantly and I still screw up? The cue isn't effective. Policy that doesn't affect outcomes isn't very effective.

## Phase 5: Governance

Once cues started influencing behavior, I needed traceability.

Each cue has provenance metadata:

```yaml
provenance:
  policy:
    - uri: governance/policies/code-lifecycle.md
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
  verified: 2026-02-26
```

This metadata is stripped at runtime (zero tokens wasted), but a CLI can trace:

```
cue → policy → control → justification
```

Think debug symbols for policy.

Invisible when running.
Auditable when needed.

## Phase 6: Discipline Enforcement

Observation is nice.

Enforcement changes behavior.

Stop blockers now include:

* Failed test blocker
* Undocumented large-change blocker

The first few times Claude said:

> Cannot stop: last test failed.

I was annoyed.

Then I stopped hitting it.

The blocker trained me.

Guardrails aren’t just for the model.

They’re for the operator.

## What This Isn’t

Let’s clear something up.

This is not:

* “Let the AI code everything.”
* A replacement for understanding your system.
* A drop-in config you clone and profit from.
* An attempt to maximize AI usage.

This is scaffolding.

AI is good at:

* Pattern application
* Consistency
* Boilerplate
* Exploring defined solution spaces

AI is bad at:

* Memory across sessions
* Long-term strategy
* Context about your specific constraints
* Knowing when rules should bend

My job is to handle the second list.

## What I Actually Built

Right now Dev OS includes:

**Hooks**

* 25+ scripts
* 10 event types
* Context injection
* Friction logging
* Cue matching
* Discipline enforcement

**Cues**

* commit
* env
* migration
* adr
* Provenance-traceable
* Macro support

**Skills**

* Weekly review
* Complexity audit
* Design review
* Root cause analysis
* Promotion-packet impact narrative

**Governance**

* Policy docs
* Control mapping
* Staleness reporting
* Trace CLI

It sounds big.

It didn’t start big.

It started with one annoyance.

## What I’ve Learned

### 1. AI Is a Consistency Engine

Claude will follow a pattern flawlessly.

It will not invent the right pattern for your organization (at least not on purpose).

Give it the pattern.

### 2. Context Is the Real Leverage

The highest ROI work I’ve done with AI wasn’t prompt engineering.

It was context engineering.

Every improvement to context reduces:

* Re-explanation
* Off-target code
* Silent assumptions

### 3. Telemetry Is Brutally Honest

I would have guessed resource-limit errors were 10% of my failures.

They were 40%.

You can’t improve what you’re mis-measuring.

### 4. Enforcement Changes Identity

The tradeoff blocker made me someone who documents tradeoffs.

Not because I philosophically decided to.

Because I was mildly annoyed into it.

Sometimes the best productivity hack is structured irritation.

### 5. The System Should Grow From Evidence

Every new hook must answer:

> What measurable problem does this solve?

If the weekly review doesn’t show a pattern, I don’t build for it.

Speculative architecture is how you drown in cleverness.

## What’s Next

I’m testing a few hypotheses:

* Cue engagement predicts effectiveness.
* Cross-session reminders change behavior.
* Some friction is structural (tooling), not behavioral (discipline).

Questions I’m not ready to answer:

* Should cues auto-adapt?
* Does team-level telemetry help or just create noise?
* Where’s the overhead ceiling?

Because yes, there definitely is a ceiling.

More scaffolding eventually becomes drag.

The trick is staying on the right side of that curve.

## The Bigger Picture

There are two ways to use AI in development:

### 1. Delegation Fantasy

Describe feature → AI writes code → you review.

Fast at first.
Fragile over time.

### 2. Structured Collaboration

You:

* Define constraints
* Encode policy
* Provide context
* Instrument feedback

AI:

* Applies patterns
* Maintains consistency
* Accelerates defined moves

Dev OS is my attempt at following the second way.

---

AI is neither a junior contributor nor a senior decision-maker. It's a high-capacity pattern application system without persistent state.

I added:

- External memory
- Explicit constraints
- Instrumented feedback

Only then did it become reliably productive.

---

*The full implementation lives in my [dotfiles](https://github.com/meaganewaller/.dotfiles). It’s tailored to my workflow. Don’t copy it blindly.*

Build your own starting with one annoyance.<br/>
Instrument it. Measure it. Enforce it. Then repeat.