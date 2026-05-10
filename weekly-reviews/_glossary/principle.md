---
layout: glossary-term
term: Principle
short: Architectural guideline with activation and reinforcement tracking
category: analysis
related:
  - tradeoff
  - decision
  - principle-activation
aliases:
  - principles
  - architectural principle
---

An architectural guideline invoked when making decisions. Principles are tracked through activation (first invocation) and reinforcement (repeated application) for depth analysis.

## Common Principles

| Principle | Meaning |
|-----------|---------|
| Explicit over implicit | Favor clarity over magic |
| Convention over configuration | Use sensible defaults |
| Self-contained artifacts | Minimize dependencies |
| Progressive enhancement | Build incrementally |
| Design for failure | Expect and handle errors |
| Optimize for the common case | Fast path for typical usage |
| Documentation as specification | Docs are source of truth |

## Tracking

Principles are extracted from `decision_tradeoff` events:

```json
{
  "event_type": "decision_tradeoff",
  "payload": {
    "principles": [
      "explicit over implicit",
      "convention over configuration"
    ]
  }
}
```

## In Weekly Reviews

Principles appear in:
- **Principles invoked** chart
- **Architectural thinking** analysis
- **Blindspot detection** - missing principles

## Principle Lifecycle

### Activation

When a principle is first mentioned in a session, it becomes "active":

```json
{
  "event_type": "principle_activated",
  "payload": {
    "principle": "model-first",
    "activation": "first_invocation"
  }
}
```

The `principle-activator` hook detects principle mentions in tool output.

### Reinforcement

Active principles are re-surfaced when relevant to current work:

```json
{
  "event_type": "principle_reinforced",
  "payload": {
    "principles_reinforced": ["model-first", "security"],
    "file_path": "/app/models/user.rb"
  }
}
```

The `principle-reinforcer` hook reminds about active principles before Write/Edit operations.

### Depth vs Breadth

**Breadth**: Many unique principles invoked once each
**Depth**: Fewer principles applied repeatedly through decisions

High breadth with low depth suggests principles are surfaced but not guiding decisions through ambiguity.

## Analysis

The weekly review analyzes principle usage:
- Distribution across decisions
- Missing principles (e.g., no resilience principles despite failures)
- Consistency of application
- **Activation count** - How many unique principles invoked
- **Reinforcement ratio** - Depth of application (reinforced / activated)
