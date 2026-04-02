# Skill Reference Guide

## `sadd:launch-sub-agent`

**Purpose:** Dispatch a single focused sub-agent with automatic model selection, structured reasoning, and mandatory self-critique. The simplest entry point when you want context isolation without a quality verification loop.

**When to use:**
- One task that benefits from clean context (no accumulated session history)
- You trust the implementation and don't need independent judge verification
- Exploratory or low-stakes work

**How it works:**
1. Analyze task to select model (Opus / Sonnet / Haiku) and optional specialized agent
2. Construct prompt: CoT prefix + task body + self-critique suffix
3. Dispatch single sub-agent via Task tool
4. Sub-agent completes work and reports summary

**Key constraints:**
- No judge verification — self-critique only
- Orchestrator must NOT read files or implement directly
- Pass only task-relevant context to sub-agent

**Model selection guide:**

| Task type | Model |
|-----------|-------|
| Architecture, design, critical decisions | Opus |
| Standard implementation, domain-specific | Opus + specialized agent |
| Non-complex but high-volume output | Sonnet |
| Trivial, mechanical (rename, copy, format) | Haiku |
| Default (uncertain) | Opus |

---

## `sadd:do-and-judge`

**Purpose:** Execute a single task with full quality verification — meta-judge generates rubrics, implementation and meta-judge run in parallel, judge verifies, retry loop on failure.

**When to use:**
- Task output matters and self-critique isn't sufficient
- You want a quality gate before accepting results
- Any non-trivial implementation task

**How it works:**
1. Analyze task, select model
2. Dispatch meta-judge AND implementation agent **in parallel** (meta-judge first in call order)
3. Wait for both to complete; extract evaluation spec YAML and implementation summary
4. Dispatch judge with exact meta-judge YAML + implementation output
5. Parse VERDICT/SCORE/ISSUES from judge response
6. If PASS (≥ 4.0): report success with improvements as optional notes
7. If FAIL: dispatch retry implementation agent with judge feedback; return to step 4
8. After 3 failed retries: escalate to user, do not proceed

**Key constraints:**
- Meta-judge and implementation MUST be dispatched in the same message (true parallel)
- Never provide score threshold to judge
- Pass meta-judge YAML to judge verbatim — no modification
- Reuse same meta-judge spec on all retries; never re-run meta-judge
- Orchestrator reads only VERDICT/SCORE/ISSUES from judge output, not the full report

**Retry prompt:** Focuses on specific issues from judge feedback. Does NOT rewrite everything — addresses only identified gaps.

---

## `sadd:do-in-steps`

**Purpose:** Execute a complex task by decomposing it into sequential steps with dependency ordering. Each step runs with a fresh meta-judge + implementation in parallel, then judge verification before the next step proceeds.

**When to use:**
- Task has natural sequential dependencies (interface → implementation → consumers → tests)
- Later steps need outputs from earlier steps
- A failure in step N should block subsequent steps (prevents building on broken foundations)

**How it works:**
1. Create `.specs/reports/` directory
2. Analyze and decompose task into ordered steps with explicit dependencies
3. Select model per step based on complexity/risk/scope
4. For each step:
   a. Dispatch meta-judge AND implementation **in parallel** (meta-judge first)
   b. Wait for both; extract spec YAML + "Context for Next Steps" from implementation
   c. Dispatch judge with step's meta-judge YAML
   d. If PASS: accumulate context, proceed to next step
   e. If FAIL: retry with feedback (reuse same meta-judge spec); escalate after 3 failures
5. Final summary report after all steps pass

**Key constraints:**
- Do NOT proceed to next step if current step fails judge verification
- Each step gets its OWN meta-judge (new meta-judge per step, not shared across steps)
- Reuse same step's meta-judge spec across retries within that step
- Keep context summaries lean (max ~200 words per completed step)
- Sub-agents can read files directly; don't pass file contents through orchestrator

**Context passing format:**
```
## Context for Next Steps
### Files Modified
- path/to/file (brief description)
### Key Changes Summary
- 3-5 bullet points
### Decisions That Affect Later Steps
- ...
### Warnings for Subsequent Steps
- ...
```

---

## `sadd:do-in-parallel`

**Purpose:** Apply the same task to multiple independent targets simultaneously. One meta-judge per target (all in parallel), then one implementation per target (parallel), then one judge per target (dispatched as each implementation completes).

**When to use:**
- Same operation across multiple files (e.g., "add JSDoc to all service files")
- Independent analysis of separate modules
- Batch refactoring where targets don't share state

**How it works:**
1. Parse targets from `--files`, `--targets`, or infer from task description
2. Validate independence (no shared files, no ordering dependencies, no shared mutable state)
3. Dispatch ALL meta-judges in parallel (one per target) in a single message
4. As each meta-judge completes, immediately dispatch its target's implementation agent
5. As each implementation completes, dispatch its judge with that target's spec YAML
6. Per-target: PASS → mark complete; FAIL → retry (max 3); FAIL after 3 → mark failed, continue others
7. Final summary table after all targets resolve

**Key constraints:**
- Failures are isolated — one target failing doesn't stop others
- Each target's judge receives ONLY that target's meta-judge YAML (not combined specs)
- Do NOT wait for all meta-judges before starting implementations — start each implementation immediately after its meta-judge completes
- Context isolation per target — each agent gets only what's relevant to its specific target
- Maximum ~10-15 targets per batch for manageability

**Flow diagram:**
```
Meta-Judge A ──► Impl A ──► Judge A ──► PASS/FAIL
Meta-Judge B ──► Impl B ──► Judge B ──► PASS/FAIL  (all started in parallel)
Meta-Judge C ──► Impl C ──► Judge C ──► PASS/FAIL
```

---

## `sadd:judge`

**Purpose:** Evaluate work already produced in the current session. Two-phase: meta-judge generates criteria, then judge evaluates against those criteria.

**When to use:**
- Work was just completed in this session and you want independent quality assessment
- Report-only evaluation — no changes made, just findings presented

**How it works:**
1. Extract evaluation context from conversation: original task, output produced, files modified
2. Dispatch meta-judge with that context
3. After meta-judge completes, dispatch judge with exact spec YAML + work context
4. Validate evaluation output (all criteria scored, evidence present)
5. Present results to user with follow-up options

**Key constraints:**
- This is report-only — findings are presented, not automatically acted on
- Pass only extracted context to sub-agents, not the entire conversation
- Never provide score threshold to judge

**Scoring interpretation:**

| Score | Label | Recommendation |
|-------|-------|----------------|
| 4.50–5.00 | Excellent | Ready as-is |
| 4.00–4.49 | Good | Minor improvements optional |
| 3.50–3.99 | Acceptable | Improvements recommended |
| 3.00–3.49 | Needs Improvement | Address before use |
| 1.00–2.99 | Insufficient | Significant rework needed |

---

## `sadd:judge-with-debate`

**Purpose:** High-rigor evaluation through multi-round debate between three independent judges. Use when a single judge's verdict is insufficient for the stakes involved.

**When to use:**
- High-stakes decisions where accuracy of evaluation matters more than speed
- When you expect genuine disagreement between evaluators (complex trade-offs)
- Architecture reviews, security assessments, critical code paths

**How it works:**
1. Create `.specs/reports/` directory
2. Dispatch meta-judge (runs ONCE; same spec used by all judges across all rounds)
3. Dispatch 3 independent judges in parallel; each writes to `.specs/reports/{name}-{date}.[1|2|3].md`
4. Check consensus: all overall scores within 0.5 points, no criterion gap > 1 point
5. If no consensus and rounds < 3: dispatch 3 debate agents in parallel; each reads others' reports from filesystem and appends debate section to their own report
6. After debate, recheck consensus; repeat up to 3 rounds
7. If consensus: synthesize final report with averaged scores
8. If no consensus after 3 rounds: report disagreements, flag for human review

**Key constraints:**
- Judges communicate only through the filesystem — orchestrator does not mediate
- Meta-judge runs ONCE; same spec across all 3 judges and all debate rounds
- Judges append to their own report file (never create new files per round)
- Orchestrator does NOT read full report files (context overflow risk) — only parses scores from judge return values
- Evidence-based position changes: judges revise only when they find the counter-argument's evidence compelling

---

## `sadd:multi-agent-patterns`

**Purpose:** Reference guide for multi-agent architecture concepts and patterns. Invoke this when designing a complex multi-agent workflow or when you need to understand trade-offs between patterns.

**Content covers:**
- Why multi-agent architectures exist (context bottleneck, parallelization, specialization)
- Three architectural patterns (supervisor, peer-to-peer, hierarchical) with trade-offs
- Context isolation mechanisms and trade-offs
- Consensus and coordination strategies (voting, debate, weighted contributions)
- Failure modes and mitigations
- Memory architecture (working, session, long-term, entity, temporal knowledge graphs)
- File-based memory patterns for multi-agent coordination

---

## `sadd:subagent-driven-development`

**Purpose:** Execute a pre-written implementation plan by dispatching fresh sub-agents per task with code review checkpoints between tasks.

**When to use:**
- You have an existing plan document and want to execute it with quality gates
- Tasks are either sequential (dependent) or parallel (independent)
- You want automated progress tracking (TodoWrite) with reviews between tasks

**Sequential flow:** One sub-agent per task → code reviewer sub-agent → apply feedback → next task

**Parallel flow:** Batch of tasks → all run in parallel → review after batch → next batch

**Key constraints:**
- Never dispatch multiple implementation sub-agents to the same target in parallel (file conflicts)
- Never skip code review between tasks
- Stop and ask for help when blocked — don't guess or force through failures

---

## Agents (not directly invokable)

### `sadd:judge`
Applied by orchestrator skills, not directly by users. Applies meta-judge evaluation specifications mechanically. Calibrated to be strict: default score is 2, scores above 3 require specific cited evidence. Generates contrastive rules (`.claude/rules/`) when it identifies systemic patterns worth propagating.

### `sadd:meta-judge`
Applied by orchestrator skills, not directly by users. Generates task-specific evaluation specifications (rubrics, checklists, scoring criteria) before implementation runs. Uses Recursive Rubric Decomposition (RRD) to decompose broad criteria into fine-grained, discriminative dimensions. Outputs structured YAML to a scratchpad file.
