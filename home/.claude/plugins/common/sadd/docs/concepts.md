# Core Concepts

## Why sub-agents exist: context isolation

The primary purpose of sub-agents is not role-play or organizational metaphor — it is **context isolation**. A single agent working through a complex task accumulates context: tool outputs, intermediate reasoning, file contents, retrieved text. This accumulation degrades quality in predictable ways (lost-in-middle effect, attention scarcity, context poisoning).

Sub-agents solve this by partitioning work. Each agent starts with a clean context window containing only what it needs for its specific subtask. Results flow back to the orchestrator through structured summaries or shared files, never by copying raw context.

## The orchestrator's role

The orchestrator (the skill you invoke) does not implement. Its only job is:
1. Analyze the task and decide how to decompose it
2. Construct focused prompts for sub-agents
3. Dispatch sub-agents via the Task tool
4. Parse structured outputs and route results
5. Escalate to the user when things fail beyond recovery

If an orchestrator reads implementation files, writes code, or runs bash commands directly — it has failed. This is a hard constraint, not a style preference.

## The meta-judge → judge verification loop

Self-critique is unreliable. An agent that just wrote code has the same blind spots when it reviews that code. Independent evaluation from a separate agent with a clean context is far more likely to catch genuine deficiencies.

But independent evaluation without structure devolves into vague impressions. The meta-judge solves this: before any implementation begins, a separate agent generates a task-specific evaluation rubric — concrete scoring criteria, boolean checklists, and weighted dimensions. The implementation agent works in parallel (so there's no time penalty). Then the judge applies the rubric mechanically.

The key properties that make this work:

**Meta-judge runs before seeing the implementation.** It generates criteria based on what *should* be there, not on what was actually produced. This prevents the judge from being anchored to whatever the implementer produced.

**Judge never knows the pass threshold.** The orchestrator withholds the score threshold (4.0/5.0) from the judge prompt. If the judge knows the threshold, it will unconsciously score around it. Without it, scores reflect actual quality.

**Meta-judge spec is reused on retries.** If the judge fails the implementation, the orchestrator dispatches a new implementation agent with the judge's feedback. The *same* meta-judge spec is used for re-evaluation. The evaluation criteria don't change; the implementation must improve to meet them.

**Default score is 2 (adequate).** The judge is calibrated to require specific evidence for any score above 2. Score 3 is "rare," score 4 is "less than 5% of evaluations," score 5 is "less than 1%." This prevents grade inflation.

## Scoring scale

| Score | Label | Meaning |
|-------|-------|---------|
| 1 | Below Average | Basic requirements met with minor issues |
| 2 | Adequate (DEFAULT) | Meets all requirements, almost no issues |
| 3 | Rare | All requirements met with specific evidence |
| 4 | Excellent | Exemplary; evidence it cannot be done better |
| 5 | Overly Perfect | Exceeds requirements significantly |

Pass threshold: ≥ 4.0, or ≥ 3.0 with all issues low-priority.

## Prompt anatomy: CoT + task + self-critique

All sub-agent prompts share a three-part structure:

**Zero-shot Chain-of-Thought prefix (first):** Instructs the agent to reason through the problem before acting — what is being asked, what constraints exist, what could go wrong. This prefix must appear first, before any task content.

**Task body (middle):** The specific work to do — constrained to the agent's scope, with clear output requirements. Context passed to each agent is minimal: only what's relevant to *this* subtask.

**Self-critique suffix (last):** Before completing, the agent generates verification questions specific to its task and answers them with evidence. If any reveal gaps, it fixes them before reporting. This is mandatory and must appear last.

## Context passing between steps

For sequential tasks (`do-in-steps`), each completed step passes a structured summary forward — not file contents, but:
- Files modified (paths only)
- Key changes (3-5 bullets)
- Decisions that affect later steps
- Warnings for subsequent steps

Sub-agents in later steps can read files directly if they need details. The orchestrator's context should stay lean.

## Memory: files as shared state

For multi-agent coordination, the file system is the default shared memory:
- **Handoff files:** Agent A writes state, Agent B reads and continues
- **Result aggregation:** Multiple parallel agents write to separate files, orchestrator reads all
- **Scratchpads:** Judges and meta-judges write analysis to `.specs/scratchpad/` (gitignored)
- **Reports:** Long-form judge evaluation reports go to `.specs/reports/`

The `create-scratchpad.sh` script creates ephemeral scratchpad files with random hex IDs and ensures the directory is gitignored.

## Isolation vs. coordination trade-offs

| Mechanism | Isolation | Flexibility | Use when |
|-----------|-----------|-------------|----------|
| Instruction passing | High | Low | Simple, well-defined subtasks |
| File system memory | Medium | High | Complex shared state, multi-step |
| Full context delegation | None | Maximum | Sub-agent needs complete understanding (use sparingly) |

## Architecture patterns

Three patterns exist for organizing multi-agent work:

**Supervisor/Orchestrator:** A central agent decomposes work, delegates to specialists, synthesizes results. Use for complex tasks with clear decomposition. Risk: supervisor context becomes bottleneck; supervisor may paraphrase sub-agent outputs incorrectly (telephone game problem). Fix: let sub-agents write to shared files rather than having supervisor rewrite everything.

**Peer-to-Peer/Swarm:** Agents communicate via shared files with no central controller. Any agent can hand off to another. Use for flexible exploration where rigid planning is counterproductive. Risk: divergence without central state keeper.

**Hierarchical:** Agents organized in layers — strategy, planning, execution. Use for large-scale projects with clear layered structure. Risk: coordination overhead between layers, misalignment between strategy and execution.

All three patterns apply the same quality loop: meta-judge generates criteria, implementation runs, judge verifies.
