# SADD — Sub-Agent Driven Development

A Claude Code plugin for orchestrating multi-agent work with structured quality verification.

SADD exists because single-agent execution has hard limits: context windows fill up, long tasks accumulate drift, and self-critique is unreliable. This plugin addresses those limits by decomposing work across agents with isolated context windows, then verifying outputs with independent judges before accepting results.

## When to use this plugin

Use SADD when:
- A task is too large or complex for a single agent to handle cleanly
- You need independent verification of output quality, not just self-critique
- You have multiple independent tasks that can run in parallel
- A complex task has sequential dependencies that must be built in order

Do NOT use SADD when:
- The task is small and well-defined (just do it directly)
- Context isolation offers no benefit (simple single-file edits)
- Coordination overhead would exceed the work itself

## Plugin structure

```
sadd/
├── docs/              # This directory — plugin documentation
├── skills/            # Invokable skills (user-facing entry points)
│   ├── launch-sub-agent/       # Single task → single sub-agent
│   ├── do-and-judge/           # Single task → implementation + judge loop
│   ├── do-in-steps/            # Complex task → sequential steps + judge per step
│   ├── do-in-parallel/         # Batch task → parallel agents + judge per target
│   ├── judge/                  # Evaluate work from the current session
│   ├── judge-with-debate/      # Multi-judge debate for high-stakes evaluation
│   ├── multi-agent-patterns/   # Reference: architecture pattern guide
│   └── subagent-driven-development/  # Reference: plan execution patterns
├── agents/            # Sub-agent definitions (invoked by skills, not directly)
│   ├── judge.md       # Strict evaluator — applies meta-judge specs
│   └── meta-judge.md  # Rubric writer — generates evaluation specifications
└── scripts/
    └── create-scratchpad.sh   # Creates ephemeral scratchpad files in .specs/
```

## Quick-reference: choosing a skill

| Situation | Use |
|-----------|-----|
| One task, want isolated context | `sadd:launch-sub-agent` |
| One task, want verified quality | `sadd:do-and-judge` |
| Complex task with dependencies | `sadd:do-in-steps` |
| Same task across many files/targets | `sadd:do-in-parallel` |
| Evaluate work already done | `sadd:judge` |
| High-stakes evaluation, want debate | `sadd:judge-with-debate` |
| Learning about multi-agent patterns | `sadd:multi-agent-patterns` |
| Executing a pre-written plan | `sadd:subagent-driven-development` |

## The quality loop (core pattern)

All execution skills (`do-and-judge`, `do-in-steps`, `do-in-parallel`) use the same verification loop:

```
Meta-Judge (parallel) ──┐
                         ├── Judge ──► PASS (score ≥ 4) → done
Implementation ──────────┘         └── FAIL → retry with feedback (max 3x)
```

The meta-judge generates task-specific rubrics *before* seeing the implementation. The judge applies those rubrics *after*. Neither knows the pass threshold. See `concepts.md` for why this matters.

## Key invariants

1. **The orchestrator never implements.** Skills dispatch sub-agents for all work — no direct file reads, writes, or bash commands.
2. **Context isolation is primary.** Each sub-agent gets only what it needs. No full conversation history passed through.
3. **Meta-judge runs once per task, reused on retries.** The evaluation criteria don't change between retry attempts.
4. **Judges never know the score threshold.** Prevents score anchoring bias.
5. **Failures are reported, not hidden.** After max retries, escalate to the user rather than proceeding.
