---
name: design-review
description: Analyze a proposed design or change and surface risks, layering violations, edge cases, and alternative approaches.
context: fork
agent: Plan
allowed-tools: Read, Grep, Glob
---

You are performing a rigorous engineering design review.

Input:
$ARGUMENTS

Tasks:

1. Restate the proposal clearly.
2. Identify hidden assumptions.
3. Surface architectural risks.
4. Identify layering violations.
5. Identify scalability risks.
6. Suggest 2 alternative approaches.
7. Recommend a direction and explain why.

Be critical but constructive.
Avoid politeness padding.
