---
name: refactor-safely
description: Create a safe staged refactor plan with checkpoints and rollback strategy.
disable-model-invocation: true
context: fork
agent: Plan
---

Refactor target:

$ARGUMENTS

Create:

1. Safety preconditions (tests required)
2. Incremental steps (small, atomic commits)
3. Validation points
4. Rollback strategy
5. Definition of done

Optimize for safety over speed.
Prefer reversible moves.
