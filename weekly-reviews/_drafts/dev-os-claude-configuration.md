---
title: "Building Dev OS: Engineering Telemetry for AI-Assisted Development"
date: 2026-02-27
status: draft
tags: [claude-code, developer-tools, telemetry, productivity]
---

# Building Dev OS: Engineering Telemetry for AI-Assisted Development

There's a tempting narrative around AI coding assistants: just describe what you want, and the AI builds it. Offload the tedious parts. Let the machine handle implementation while you think big thoughts.

I've found this framing unhelpful.

AI assistants are genuinely powerful, but they're not magic. They excel at certain tasks and struggle with others. They lack memory, context, and judgment about *your* specific codebase, patterns, and preferences. Treating an AI as a universal hammer leads to frustration—yours and the model's.

What I've been building instead is a **support system**: infrastructure that helps the AI do what it's good at, compensates for what it's not, and learns from our collaboration over time. The goal isn't to offload work. It's to build the scaffolding that makes AI assistance actually work for *my* workflow.

## The Problem: Context Is Everything

Claude Code is capable, but each session starts fresh. The assistant doesn't remember that you've hit the same file-not-found error twelve times this week, or that you always forget to document tradeoffs on large changes, or that your commit messages tend to drift from conventional format under deadline pressure.

Without context, the AI can't learn your patterns. Without memory, every session is a cold start. Without guardrails, the AI's confidence can outpace its accuracy.

The gap isn't capability—it's context. And that's something I can provide.

## The Approach: Build What You Need, When You Need It

I didn't start with a grand architecture. I started with annoyance.

Claude Code has a hooks system—scripts that run on events like `PostToolUse`, `SessionStart`, and `Stop`. The first hook I wrote solved a specific problem: I kept ending sessions with failing tests, then having to restart and re-establish context. So I added a blocker: can't stop if the last test failed.

That's it. One hook, one problem, five minutes of work.

But it worked. And it made me wonder: what other friction could I address this way? Not by asking Claude to be smarter, but by giving Claude better information and clearer boundaries.

The system grew from there—not from a design doc, but from observed needs.

## Phase 1: Friction Detection

The first hook I built was `skill-gap-detector.sh`. Every time a tool fails, it classifies the error into a taxonomy:

```
Primary Domains:
├── syntax      - Parse errors, malformed input
├── type        - Type mismatches, inference failures
├── dependency  - Missing packages, version conflicts
├── permission  - Access denied, auth failures
├── state       - File not found, resource limits
├── config      - Env vars, misconfiguration
├── testing     - Test failures, assertions
└── build       - Compilation, bundling errors
```

Each failure gets logged to `~/.claude/skill-friction-log.jsonl` with the domain, subdomain, error excerpt, and hints for remediation.

Then came `friction-escalator.sh`, which runs at session start. If any domain has 3+ occurrences in the last 24 hours, it surfaces a reminder:

```
Repeated friction in [state]: 15 hits.
Subdomains: file-not-found(10) resource-limit(5).
Hint: Use offset/limit for large files.
```

Suddenly, patterns that would have taken weeks to notice became visible in days. I discovered I was hitting resource limits constantly—not because I didn't know about chunked operations, but because in the flow of work, I kept forgetting to apply them.

## Phase 2: Impact Tracking

Friction tells you where you're struggling. But what about where you're succeeding?

I added `impact-extractor.sh` to log every file write with metadata: change type (refactor, architecture, bugfix), risk level, and inferred skill domains from the file path. This creates `~/.claude/impact-log.jsonl`—a record of everything I've built.

Other hooks followed:
- `large-diff-escalator.sh`: Flags changes over 250 lines
- `reversal-detector.sh`: Detects when I undo recent work
- `dependency-change-detector.sh`: Tracks package.json/Gemfile changes

Each emits events to a central stream: `~/.claude/dev-os-events.jsonl`.

## Phase 3: The Weekly Review

With a week of events accumulated, I built `/weekly-review`—a skill that aggregates everything into a dashboard:

- **Execution metrics**: writes, failures, test stability
- **Friction analysis**: top domains, subdomains, hints
- **Discipline flags**: large changes without tradeoffs, reversals
- **Per-project breakdown**: which repos got attention

The skill generates charts, a markdown report, and an HTML dashboard. But more importantly, it prompts Claude to synthesize the data into actionable insights:

> "This was a high-throughput infrastructure week with 45% friction rate. The friction stems from environmental instability rather than capability gaps. Precision move: implement idempotent operation patterns in hook scripts."

I now have weekly reviews that connect my tactical work to strategic patterns.

## Phase 4: Cues—Compiled Policy

Friction detection is reactive. What about proactive guidance?

I built a **cue system**: declarative guidance files that inject into context when triggers match. Each cue has:

- **Triggers**: regex patterns for prompts, commands, or file paths
- **Scope**: agent-only, subagent-only, or both
- **Content**: the actual guidance (kept concise for context efficiency)

Example: when I mention "commit" or run `git commit`, the commit cue fires:

```markdown
# Commit / push cue

- Prefer **conventional commits**: `type(scope): message`
- Keep the subject line under 72 characters
- Before pushing, ensure tests pass
```

Cues are "compiled policy"—I read governance documents, interpret them for the AI context, and compress them into directive form. The source policy exists for humans; the cue exists for Claude.

### Semantic Matching

Regex triggers miss intent. If I ask "how should I structure this change record?" I mean commits, but "commit" doesn't appear.

So I added semantic matching using gzip normalized compression distance (NCD). Each cue has a `description` and `vocabulary` field. When regex fails, the system checks if any vocabulary word appears, then falls back to NCD similarity against the description.

This catches intent-based triggers that would otherwise slip through.

### Engagement Tracking

Are cues actually helping? I added `cue_fired` events to the telemetry stream. Now the weekly review shows:

- Which cues fired and how often
- Trigger type distribution (prompt vs. bash vs. file)
- Dormant cues that might need better triggers

This closes the feedback loop: write cue → observe engagement → refine triggers.

## Phase 5: Governance

With cues driving AI behavior, a question emerged: how do I know my cues align with policy?

I added **provenance metadata** to cue frontmatter:

```yaml
provenance:
  policy:
    - uri: governance/policies/code-lifecycle.md
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
      justifications:
        - Conventional commits classify changes
        - Atomic commits enable independent review
  verified: 2026-02-26
  rationale: Why this cue exists
```

The provenance is stripped at runtime (zero tokens, zero latency), but a governance CLI can trace any cue back to its policy source:

```bash
dotfiles governance --trace commit
# Shows: cue → policy → controls → justifications
```

This is "debug symbols for compiled policy"—the chain is walkable when you need it, invisible when you don't.

## Phase 6: Discipline Enforcement

Observation is useful. Enforcement is transformative.

I added blockers to the `Stop` event:
- `hard-stop-test-blocker.sh`: Can't end session if last test failed
- `pending-tradeoff-blocker.sh`: Can't end session with undocumented large changes

The first time Claude told me "Cannot stop: last test failed," I was annoyed. The fifth time, I'd internalized the habit. The blocker wasn't just catching mistakes—it was training behavior.

## What This Isn't

Before cataloging the current system, I want to be clear about what I'm *not* building.

**This isn't "let Claude do everything."** I'm not trying to describe features in plain English and have AI implement them end-to-end. That workflow exists and sometimes it's appropriate. But it's not the only mode, and it's often not the best mode.

**This isn't a replacement for understanding your code.** Cues encode *my* judgment about how things should work. Telemetry surfaces *my* patterns. The AI helps apply these consistently—it doesn't generate them.

**This isn't a fixed system you download and run.** My hooks address my friction. My cues encode my team's conventions. The value isn't in copying my configuration—it's in building your own through the same iterative process.

**This isn't about maximizing AI usage.** Some tasks are better done without AI. Some decisions shouldn't be delegated. The goal is effective collaboration, not maximum delegation.

The question isn't "how do I get AI to do more?" It's "what support does AI need to do its part well?"

## Where It's At Now

The system currently includes:

**Hooks** (25+ scripts across 10 event types):
- Session context injection
- Friction detection and escalation
- Impact and pattern extraction
- Cue matching and injection
- Discipline enforcement

**Cues** (4 and growing):
- commit, env, migration, adr
- Each with provenance traceability
- Macro support for dynamic content

**Skills** (16 total):
- Weekly review with charts and synthesis
- Complexity audit, design review, root cause analysis
- Impact narrative for promotion packets

**Governance**:
- Policy documents with control mappings
- Provenance verification CLI
- Coverage and staleness reporting

**Documentation** (per ADR-0001):
- Layered by audience (users, contributors, operators, auditors)
- Single-source-of-truth with cross-linking

## What I've Learned

### 1. AI Excels at Consistency, Not Judgment

Claude is remarkably good at following patterns—if you show it the pattern. It's less good at knowing when to deviate. Cues work because they provide the pattern at the right moment. Blockers work because they encode judgment I've already made.

I'm not asking Claude to decide whether this commit needs a conventional format. I'm telling it "commits should use conventional format" and letting it apply that consistently. That's what AI does well.

### 2. Your Job Is Context Provision

The bottleneck in AI-assisted development isn't the AI's capability—it's the AI's context. Every hour I spend improving context provision pays back tenfold in reduced re-explanation and fewer off-target suggestions.

This reframes the work: I'm not trying to make Claude smarter. I'm trying to make sure Claude has what it needs to apply its intelligence effectively.

### 3. Telemetry Reveals What You Actually Need

I built several hooks that seemed useful in theory but never fired in practice. Telemetry showed me. I also discovered friction patterns I'd never consciously noticed—resource-limit errors were 40% of my failures, but I would have guessed maybe 10%.

You can't build what you need if you don't know what you need. Observation comes first.

### 4. Enforcement Trains Both Parties

The tradeoff blocker was initially annoying. "I know this change is fine, just let me stop." But the friction was the point. After a few weeks, I started documenting tradeoffs *before* Claude reminded me—the blocker had trained a habit.

Guardrails aren't just for the AI. They're for the human too.

### 5. The System Is Never Done

My first hook was 15 lines. The system now has 25+ hooks, 4 cues, a governance layer, and a weekly review skill. But it's not "finished"—it's *fitted*. Fitted to my workflow, my friction points, my preferences.

Your system will look different. That's the point.

## What's Next

The roadmap isn't a feature list—it's a set of hypotheses to test. Each emerged from observing the current system.

### Hypotheses I'm Testing Now

- **Cue engagement predicts effectiveness**: If a cue fires often but I keep making the same mistakes, the cue isn't working. Need follow-through tracking.
- **Historical patterns improve current sessions**: Surfacing "you hit this error 5 times last week" might change behavior. Need cross-session learning.
- **Some friction is structural, not behavioral**: Resource-limit errors won't go away with reminders—they need different tooling. Need to distinguish friction types.

### Questions I'm Not Ready to Answer

- **Should cues adapt automatically?** Adjusting trigger sensitivity based on engagement sounds smart, but might overfit to recent behavior.
- **Would team telemetry help?** Aggregate patterns might reveal shared friction, but might also just be noise.
- **Where's the ceiling on this approach?** At some point, more scaffolding creates more overhead than it saves. I don't know where that point is yet.

### The Meta-Principle

Every addition to the system should come from observed need, not theoretical appeal. The weekly review already shows me cue engagement; if that reveals a problem, I'll build a solution. If it doesn't, I won't build preemptively.

The system grows by indexing for what's actually needed, not what might be needed.

## The Bigger Picture

There's a version of AI-assisted development where you try to offload everything. Describe the feature, let the AI build it, review the result. It sounds efficient.

In practice, it's fragile. The AI makes assumptions you didn't intend. It over-engineers or under-engineers. It doesn't know your team's conventions, your production constraints, your technical debt. You spend more time correcting than you saved by delegating.

The alternative isn't to use AI less—it's to use AI *better*. That means:

1. **Know what AI does well**: Pattern application, consistency, boilerplate, exploration of defined problem spaces.
2. **Know what AI needs help with**: Context about your specific codebase, memory of past decisions, judgment about when rules should bend.
3. **Build the scaffolding**: Hooks that provide context. Cues that encode policy. Blockers that enforce discipline. Telemetry that reveals patterns.
4. **Iterate based on observation**: Don't guess what you need. Measure what's actually causing friction, then address it.

Dev OS isn't about making Claude smarter. It's about building the support structure that lets Claude's intelligence actually help.

The AI is a collaborator with specific strengths and limitations. My job is to set up the collaboration for success—clear context, appropriate boundaries, feedback loops that improve over time.

That's not offloading work. That's doing the work of making AI assistance actually work.

---

*The full implementation lives in my [dotfiles](https://github.com/meaganewaller/.dotfiles/tree/main/home/.claude). The system is specific to my workflow, but the approach generalizes: observe, measure, iterate, and build the scaffolding your collaboration needs.*
