---
name: design-review
description: Perform a structured architectural review before implementing significant changes. Use before large refactors, new systems, or cross-cutting changes.
disable-model-invocation: true
context: fork
agent: Plan
allowed-tools: Read, Grep, Glob
---

You are conducting a structured design review for:

$ARGUMENTS

Perform the following:

1. Identify system boundaries involved
2. List layers touched (models, services, infra, UI, etc.)
3. Identify cross-cutting concerns
4. Enumerate tradeoffs
5. Identify failure modes
6. Assess risk level (low / medium / high)
7. Recommend test strategy

Output a structured design memo.

Be concrete. Reference actual files where relevant.
