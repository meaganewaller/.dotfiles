---
name: refactor-safely
description: Plan a safe refactor with guardrails and rollback strategy.
disable-model-invocation: true
context: fork
agent: Plan
---

Refactor target:

$ARGUMENTS

1. Identify invariants that must not change
2. Define measurable success criteria
3. Define rollback strategy
4. Identify high-risk surfaces
5. Propose incremental steps (small commits)

Optimize for safety over speed.
