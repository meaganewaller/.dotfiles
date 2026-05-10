---
layout: glossary-term
term: Tradeoff
short: Documented architectural decision with alternatives
category: analysis
related:
  - principle
  - large-change
  - decision
aliases:
  - tradeoffs
  - decision tradeoff
---

An architectural decision with documented alternatives, pros/cons, and guiding principles. Captured as `decision_tradeoff` events.

## Structure

A tradeoff document includes:

1. **Summary** - What decision was made
2. **Options** - Alternatives considered
3. **Tradeoffs** - Pros/cons of each option
4. **Principles** - Architectural guidelines applied
5. **Rationale** - Why this option was chosen

## Event Structure

```json
{
  "event_type": "decision_tradeoff",
  "payload": {
    "summary": "Chose jq over Python for JSON processing",
    "options": ["jq", "Python", "Node.js"],
    "tradeoffs": [
      "jq: shell-native, no dependencies, limited logic",
      "Python: powerful, adds dependency"
    ],
    "principles": ["convention over configuration"]
  }
}
```

## When to Document

Tradeoffs should be documented for:
- Large changes (> 250 lines)
- Architectural decisions
- Technology choices
- Process changes

## In Weekly Reviews

Tradeoffs appear in:
- **Decisions documented** count
- **Principles invoked** analysis
- **Discipline flags** - coverage rate
