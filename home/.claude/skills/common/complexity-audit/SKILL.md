---
name: complexity-audit
description: Audit a module or system for accidental complexity and unnecessary coupling.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

Audit:

$ARGUMENTS

Identify:

- Circular dependencies
- Cross-layer leakage
- Implicit state
- Hidden invariants
- God objects
- Over-configuration

Classify findings:
- Harmless
- Concerning
- Dangerous
