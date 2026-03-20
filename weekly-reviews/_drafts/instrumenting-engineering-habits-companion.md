---
title: "Instrumenting Your Engineering Habits: Speaker Companion"
date: 2026-03-09
status: draft
type: presentation-companion
presentation: ~/.claude/presentations/instrumenting-engineering-habits.md
tags: [claude-code, developer-tools, telemetry, presentation, habits]
---

# Instrumenting Your Engineering Habits

## Companion Document & Speaker Notes

This document accompanies the presentation of the same name. Use it for preparation, as a reference during Q&A, or as a standalone written version of the talk.

**Presentation file:** `~/.claude/presentations/instrumenting-engineering-habits.md`
**Runtime:** ~40 minutes + Q&A
**Audience:** Engineers interested in AI-assisted development, productivity systems, or developer tooling

---

## Talk Structure

| Section | Slides | Time | Purpose |
|---------|--------|------|---------|
| Opening | 1-6 | 3 min | Hook and frame the problem |
| Part 1: Visibility Problem | 7-14 | 8 min | Establish why this matters |
| Part 2: Making It Visible | 15-30 | 12 min | The instrumentation layer |
| Part 3: Making It Stick | 31-48 | 15 min | The reinforcement layer |
| Closing | 49-55 | 5 min | Meta-pattern and invitation |

---

# Opening (3 min)

## The Hook

Start with energy but not hype. You're inviting them into a problem they recognize.

**Script:**

> "Quick show of hands—how many of you have used an AI coding assistant? Claude, Copilot, Cursor, whatever."
>
> *[Wait for hands]*
>
> "Okay, keep your hand up if you've ever told the AI to follow a convention—maybe 'use conventional commits' or 'follow our error handling pattern'—and it forgot by the next message."
>
> *[Hands stay up, knowing laughs]*
>
> "Now—and be honest—keep your hand up if *you've* ever forgotten your own conventions halfway through a long session."
>
> *[Pause for recognition]*
>
> "Yeah. Me too."

## The Frame

**Script:**

> "So here's the thing I've been thinking about: the problem isn't that AI is forgetful. The problem is that collaboration—whether it's human-AI or just you at 4pm vs you at 9am—is invisible by default.
>
> You can't debug what you can't see. And you can't sustain what you don't reinforce.
>
> That's what I want to talk about today."

---

# Part 1: The Visibility Problem (8 min)

## Key Message

Most developers have strong opinions about best practices but no data about their actual practices.

## The Invisible Workflow

**Script:**

> "Let me ask you something. When you're working—writing code, reviewing PRs, debugging—how much of that is actually recorded anywhere?
>
> When you read a file, there's no record. When you make a decision about architecture, the reasoning evaporates the moment you move on. When you hit an error and retry three times, who's counting? When you say 'I'm going to follow separation of concerns here,' does anyone check later if you actually did?"

*[Pause for effect]*

> "We instrument our applications obsessively. Metrics, traces, logs, dashboards. If a production system had this little observability, we'd call it a liability.
>
> But our own workflow? Black box."

## The Discovery

This is your first "proof" moment. Real data is more compelling than hypotheticals.

**Script:**

> "So a few weeks ago, I started instrumenting. Every time a tool fails in my Claude Code sessions, a hook classifies the error into a taxonomy.
>
> After one week, I pulled the data. And I found something embarrassing."

**Live demo option:**
```bash
jq -s 'group_by(.domain) | map({domain: .[0].domain, count: length}) | sort_by(-.count)' \
  ~/.claude/skill-friction-log.jsonl | head -10
```

**Script:**

> "878 resource-limit errors. I was reading files that were too large, running searches that matched thousands of results. The same mistake. Hundreds of times.
>
> And here's the thing—I *knew* about chunked reading. I'd written documentation about it. But in the flow of work, I kept forgetting to apply it.
>
> That was the moment I realized: knowing isn't the same as doing. And if I wanted to actually change my behavior, I needed to start by seeing it clearly."

---

# Part 2: Making It Visible (12 min)

## Key Message

Treat your development process like a production system. Instrument it.

## Layer 1: Friction Telemetry

**What it solves:** Repeated mistakes you don't notice.

**Script:**

> "The first layer is friction telemetry. Every tool failure gets classified into a taxonomy—syntax errors, type mismatches, permission issues, state problems, config issues, test failures.
>
> But here's what makes it useful: aggregation over time. One file-not-found error is noise. Fifty file-not-found errors is a pattern.
>
> A hook runs at the start of each session and checks: have I hit the same error type three or more times in the last 24 hours? If so, it surfaces a reminder."

**Example output:**
```
Repeated friction in [state]: 15 hits.
Subdomains: file-not-found(10) resource-limit(5).
Hint: Verify paths with Glob before Read. Use offset/limit for large files.
```

> "This isn't a one-time report. It's continuous feedback. The system notices my patterns before I do."

## Layer 2: Decision Traceability

**What it solves:** Lost context and forgotten reasoning.

**Script:**

> "Here's a scenario you've probably lived. You make an architectural choice. Six months later, someone—probably you—looks at it and asks 'why did we do it this way?'
>
> The code tells you *what*. It doesn't tell you what alternatives you considered, what tradeoffs you made, when you should revisit it, or what principles guided the choice.
>
> That context is gone. Unless you capture it."

**How it works:**

> "When a session makes large changes—over 100 lines modified—an agent hook runs at session end. It analyzes the conversation and extracts the decision summary, alternatives considered, tradeoffs made, and principles invoked.
>
> This writes to a version-controlled journal. Not just telemetry—*history*."

**Show a real entry:**
```markdown
# Tradeoff: 2026-03-02

**Files:** template_context.rb, install_generator.rb
**Source:** auto-capture

## Decision Summary
Extracted ERB conditionals into TemplateContext PORO for testability.

## Alternatives Considered
- Test ERB directly (rejected: 0% branch coverage)
- Nested class in generator (rejected: breaks isolated spec loading)

## Revisit If
- Template grows significantly more complex
- Coverage requirements change
```

> "This exists because the system captured it. Not because I remembered to write it."

## Layer 3: Session Health

**What it solves:** Fatigue you don't feel happening.

**Script:**

> "Long sessions correlate with more errors. This probably isn't surprising—fatigue sets in, context accumulates, you start making sloppier decisions.
>
> But here's the thing: you don't *feel* it happening. You just keep going.
>
> So I added duration monitoring. The system tracks elapsed time and classifies sessions into archetypes."

| Duration | Archetype | What's Happening |
|----------|-----------|------------------|
| <30 min | Quick | Focused task, fresh context |
| 30-60 min | Flow | Deep work zone |
| 60-120 min | Extended | Productive but tiring |
| 120-240 min | Marathon | Diminishing returns |
| >240 min | Ultramarathon | You should have stopped |

**If you have the data:**

> "In my telemetry: sessions over 2 hours have 3x the friction rate of sessions under 30 minutes. Three times."

## Layer 4: Principle Activation

**What it solves:** Breadth without depth—invoking principles but not following through.

**Script:**

> "I noticed a pattern in my sessions. Early on, I'd invoke some principle—'let's keep separation of concerns in mind.' Good intentions.
>
> Then 20 minutes later, I'd completely forget I'd said that. The principle got mentioned but never applied consistently.
>
> So I added tracking. When tool output contains principle keywords, the system marks that principle as 'active' for the session. Now there's a record of what this session claimed to care about."

## Layer 5: Loop Detection

**What it solves:** Getting stuck without realizing it.

**Script:**

> "Sometimes you get stuck. The AI tries something, it fails, it tries the same thing again. Or you edit a file, it breaks, you edit it the same way.
>
> The detector watches for patterns: same file edited multiple times without reading, error rate over 50%, no new files touched in many operations.
>
> When it triggers, it injects a prompt: 'Possible loop detected. Consider stepping back.' It doesn't block—just creates a moment of reflection."

## Layer 6: Governance

**What it solves:** Untraceable rules.

*Note: This section is optional—read your audience. Some will love it, others won't care.*

**Script:**

> "When a cue tells me 'use conventional commits,' where did that rule come from? Each cue has provenance metadata linking to the policy it implements. Debug symbols for compiled guidance."

## Transition to Part 3

*[Pause here—major section transition]*

**Script:**

> "So. We've got visibility now. Friction, decisions, session health, principles, loops. I can see what's happening.
>
> But here's what I learned: visibility alone doesn't change behavior.
>
> I *knew* I was hitting resource-limit errors. The dashboard showed me. But I kept doing it.
>
> Knowing isn't doing. Information isn't behavior change.
>
> That's where reinforcement comes in."

---

# Part 3: Making It Stick (15 min)

## Key Message

Telemetry tells you what happened. Reinforcement changes what happens next.

## Principle 1: Remind at the Point of Action

**The insight:**

Wrong time to remind: when reading documentation.
Right time to remind: when about to do the thing.

**Script:**

> "Think about when most 'best practices' get communicated. In documentation. In onboarding. In a wiki page you read once.
>
> When's the worst time to remind someone about a convention? When they're reading docs. They'll nod, agree, and forget.
>
> When's the right time? When they're about to do the thing."

**How it works:**

> "Early in a session, I'm planning something. I say 'let's keep separation of concerns in mind here.' The principle activator hook detects this, marks it as active.
>
> 20 minutes later, I'm about to edit a file. The reinforcer hook checks for active principles and injects: 'Active principle: separation of concerns. Does this change align?'
>
> The reminder appears exactly when it matters. And it's not generic advice—it's specifically the principles *I* invoked in *this* session."

**Design decisions (for Q&A):**
- Rate-limited (5-minute cooldown) to avoid noise
- Only active principles, not a firehose
- Framed as a question, not a command

## Principle 2: Friction at the Threshold

**The insight:**

Speed bumps, not walls. Create decision points at natural boundaries.

**Script:**

> "Remember the session archetypes? Here's where they become actionable."

| Threshold | Message |
|-----------|---------|
| 30 min | "Consider creating a task list to preserve context." |
| 120 min | "2-hour session. Consider committing and taking a break." |
| 240 min | "4-hour session. Friction rates increase significantly." |

> "These aren't blocks. They're speed bumps. The message arrives when you're about to continue—not after you've already burned another hour. It creates a decision point."

**Personal story:**

> "I'll be honest—I ignored the 30-minute prompt for a while. 'I'm in flow, don't interrupt me.'
>
> Then I noticed: I kept losing context in long sessions. Things I'd decided early would get forgotten.
>
> So I started actually creating task lists. Not because the prompt forced me—because I'd experienced the alternative. The prompt trained the habit."

## Principle 3: Blocking Beats Warning

**The insight:**

Warnings are easy to dismiss. Sometimes you need to just say no.

**Script:**

> "There's a spectrum of enforcement: silent, logged, advisory, warning, blocking. Most systems stop at warning. 'Hey, that file is large. Consider chunking.'
>
> The problem? Warnings are easy to dismiss. Especially when you're confident."

**When to block:**

| Blocked | Why |
|---------|-----|
| Session log full reads | Caused 99% of resource-limit errors |
| Glob `**/*` without extension | Always too broad, always fails |
| Stopping with failed tests | "Just one more thing" leads to broken commits |

**Personal story:**

> "The first time a blocker stopped me, I was annoyed. 'I know what I'm doing, let me through.'
>
> By the fifth time, I'd started doing the right thing *before* the blocker triggered.
>
> By the tenth time, the habit was internalized.
>
> Blocking is training. The friction is the point."

## Principle 4: Make the Right Thing Easy

**The insight:**

If you just block and don't help, people work around you.

**Script:**

> "When the large-file-guard detects a big file, it doesn't just say 'too big.' It says: here's exactly how to read this."

```
File has 5,847 lines. Suggested approach:
- Chunk 1: offset=1 limit=1000
- Chunk 2: offset=1001 limit=1000
- Chunk 3: offset=2001 limit=1000

For JSONL files, prefer: tail -100 file.jsonl | jq 'select(...)'
```

> "The right path is now easier than the wrong path. Copy-paste the suggestion versus figure it out yourself."

## Principle 5: Close the Loop

**The insight:**

Reinforcement without feedback is just nagging.

**Script:**

> "Every week, I run a review. Did marathon sessions decrease? Did friction drop? Did commit frequency increase?
>
> If yes—the intervention is working. If no—it failed, time to adjust.
>
> I set a target: 50% reduction in resource-limit errors. That's measurable. If I don't hit it, I'll know.
>
> Two weeks ago, I had 6 marathon sessions. This week, 2. The checkpoint prompts are working—I can see it in the data."

**The meta-point:**

> "This is how you debug behavior change. Not intuition—instrumentation. Same skills you use to debug systems."

## The Compound Effect

**Script:**

> "None of these reinforcements is transformative on its own. But they stack.
>
> File verification → fewer file-not-found errors
> Principle reinforcer → more consistent code
> Duration checkpoints → shorter sessions
> Decision auto-capture → documentation without effort
> Weekly review → patterns visible
>
> The goal isn't productivity hacks. It's infrastructure for the kind of engineer I want to be *consistently*. Not just on good days."

---

# Closing (5 min)

## The Meta-Pattern

**Script:**

> "Let me leave you with the meta-pattern here.
>
> This system—I call it Dev OS—isn't about making AI smarter. It isn't about productivity hacks. It's about making the collaboration *debuggable*.
>
> Every opaque process is a process you can't improve.
>
> You can't improve what you can't measure.
> You can't sustain what you don't reinforce.
> You can't debug what you can't trace."

## The Invitation

**Script:**

> "So here's my question for you.
>
> What's invisible in *your* workflow?
>
> What mistake do you keep making that you've never counted? What principles do you invoke but don't follow through on? What patterns would you see if you actually instrumented your process?
>
> You don't need my system. But you might need *a* system. The tools are just hooks and scripts. The insight is: treat your workflow like a production system. Instrument it. Debug it. Improve it."

**Final line:**

> "Thanks. I'm happy to take questions—or if you want to see any of this live, I can show you."

---

# Q&A Preparation

## Likely Questions

### "How much time did this take to build?"

> "About 3 weeks of active development. But I didn't build it all at once—I started with one hook that solved one problem. Then another. It grew from observed needs, not a grand plan."

### "Isn't this a lot of overhead?"

> "The hooks add maybe 50-100ms per operation. The cognitive overhead is near zero once it's set up—it just runs. The weekly review takes about 30 minutes, but it replaces time I'd spend wondering 'what did I even do this week?'"

### "Would this work for a team?"

> "Parts of it. The friction taxonomy could be shared. Cues could encode team conventions. But a lot of it is personal—my friction patterns aren't yours. I think the approach generalizes better than the specific implementation."

### "What if I don't use Claude Code?"

> "The specific hooks are Claude Code-specific. But the pattern—instrument, reinforce, review—works anywhere. You could build similar things for any editor with plugin support, or even just shell aliases and cron jobs."

### "What's the ROI?"

> "Hard to quantify precisely. But: 878 resource-limit errors down to maybe 50 a week. Marathon sessions down from 6 to 2. Decisions actually documented instead of forgotten. For me, that's worth the investment."

### "Can I see the code?"

> "It's all in my dotfiles repo—I'll share the link. But I'd encourage you to build your own from your own friction, not copy mine."

### "What would you instrument first if starting over?"

> "Friction detection. It's the highest signal-to-effort ratio. Just classifying your failures and aggregating them over time reveals patterns you'd never notice otherwise."

### "How do you avoid alert fatigue?"

> "Rate limiting and relevance. Reminders have cooldowns. Principles only surface if *you* invoked them. Warnings only appear when thresholds are actually crossed. And I keep tuning—if something fires too often without helping, I adjust the threshold or remove it."

---

# Technical Reference

## Key Files

| Component | Location |
|-----------|----------|
| Friction taxonomy | `~/.claude/hooks/common/PostToolUseFailure/skill-gap-detector.sh` |
| Decision capture | `~/.claude/settings/common/hooks.jsonc` (Stop agent) |
| Duration monitoring | `~/.claude/hooks/common/UserPromptSubmit/session-duration-monitor.sh` |
| Principle activation | `~/.claude/hooks/common/PostToolUse/principle-activator.sh` |
| Principle reinforcement | `~/.claude/hooks/common/PreToolUse/principle-reinforcer.sh` |
| Loop detection | `~/.claude/hooks/common/PostToolUse/loop-detector.sh` |
| Weekly review | `~/.claude/skills/common/weekly-review/` |

## Quick Stats to Cite

| Metric | Value |
|--------|-------|
| Total hooks | 30+ |
| Skills | 17 |
| Cues | 9 |
| ADRs | 8 |
| Resource-limit errors (before) | 878 |
| Target reduction | 50% |
| Marathon sessions (before) | 6/week |
| Marathon sessions (after) | 2/week |
| Friction multiplier (2hr+ sessions) | 3x |

## Demo Commands

**Show friction by domain:**
```bash
jq -s 'group_by(.domain) | map({domain: .[0].domain, count: length}) | sort_by(-.count)' \
  ~/.claude/skill-friction-log.jsonl | head -10
```

**Show recent decisions:**
```bash
ls -la ~/.claude/decision-journal/ | tail -10
```

**Show session durations:**
```bash
jq -s '[.[] | select(.event_type == "session_end")] | group_by(.payload.duration_category) | map({category: .[0].payload.duration_category, count: length})' \
  ~/.claude/dev-os-events.jsonl
```

---

# Handout Version

*For attendees who want the key points without the narrative:*

## The Problem

Collaboration—human-AI or human-solo—is invisible by default. You can't debug what you can't see. You can't sustain what you don't reinforce.

## The Instrumentation Layer

1. **Friction Telemetry** - Classify and aggregate tool failures
2. **Decision Traceability** - Auto-capture reasoning at session end
3. **Session Health** - Track duration, correlate with friction
4. **Principle Activation** - Mark invoked principles as active
5. **Loop Detection** - Catch stuck patterns
6. **Governance** - Trace cues to source policies

## The Reinforcement Layer

1. **Point of Action** - Remind when about to act, not when reading docs
2. **Threshold Friction** - Speed bumps at session duration boundaries
3. **Blocking** - Some things should just fail
4. **Easy Right Path** - Provide the correct approach, not just warnings
5. **Closed Loop** - Weekly review to measure intervention effectiveness

## The Meta-Pattern

- You can't improve what you can't measure
- You can't sustain what you don't reinforce
- You can't debug what you can't trace

## Start Here

1. Add friction classification to your workflow
2. Aggregate over time (daily/weekly)
3. Pick one pattern to address
4. Measure whether the intervention worked
5. Repeat

---

*Repository: github.com/meaganewaller/.dotfiles*
