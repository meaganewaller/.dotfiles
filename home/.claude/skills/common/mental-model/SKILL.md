---
name: mental-model
description: Build a mental model of a system before modifying it.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

Build a mental model of:

$ARGUMENTS

Include:

- Core abstractions
- Data flow
- Invariants
- Lifecycle
- Extension points
- Common pitfalls

Then explain:
If I change X, what breaks?
