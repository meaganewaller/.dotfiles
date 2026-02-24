---
name: risk-audit
description: Audit a change for risk surface and hidden failure modes.
disable-model-invocation: true
context: fork
agent: Explore
---

Audit the following change or file:

$ARGUMENTS

1. What assumptions does this rely on?
2. What could break silently?
3. What external systems are involved?
4. What edge cases are untested?
5. What would fail first in production?

Be skeptical.
