---
layout: glossary-term
term: Principle Activation
short: First invocation of a principle in a session
category: analysis
related:
  - principle
  - tradeoff
aliases:
  - activated principle
  - principle reinforcement
---

The tracking of when principles are first invoked (activated) and subsequently re-applied (reinforced) within a session.

## Why Track Activation?

Weekly review analysis revealed:
- **10 unique principles, each invoked once**
- "Breadth not depth" pattern
- Principles surfaced but not guiding decisions through ambiguity

## Lifecycle

### 1. Activation

When output first mentions a principle pattern:

```json
{
  "event_type": "principle_activated",
  "payload": {
    "principle": "model-first",
    "context": "",
    "activation": "first_invocation"
  }
}
```

### 2. Active Period

Principle remains "active" for the session, stored in:
```
/tmp/.claude-active-principles-{session_id}
```

### 3. Reinforcement

Before Write/Edit operations, active principles are checked for relevance:

```json
{
  "event_type": "principle_reinforced",
  "payload": {
    "file_path": "/app/models/user.rb",
    "tool": "Write",
    "principles_reinforced": ["model-first"],
    "reinforcement_count": 1
  }
}
```

## Detected Principles

The `principle-activator` hook detects mentions of:

| Pattern | Principle |
|---------|-----------|
| `model-first`, `domain model`, `sketch shape` | model-first |
| `simplify`, `make change easy`, `refactor before` | simplifying-for-change |
| `test purpose`, `meaningful test`, `test roi` | testing-with-purpose |
| `efficiency`, `resource limit`, `chunk` | efficiency |
| `auth`, `session`, `token`, `sanitize` | security |
| `retry`, `timeout`, `circuit break`, `idempotent` | reliability |

## Reinforcement Triggers

The `principle-reinforcer` matches active principles to file paths:

| Principle | Relevant Files |
|-----------|----------------|
| model-first | `models/`, new files |
| security | `auth`, `controller`, `api/` |
| reliability | `job`, `worker`, `service` |
| testing-with-purpose | `_spec.rb`, `_test.rb` |

## Metrics

### Activation Ratio
```
unique_principles_activated / total_decisions
```
Higher = more principled decision-making

### Reinforcement Depth
```
total_reinforcements / total_activations
```
Higher = principles guiding through ambiguity, not just surfaced once

## In Weekly Reviews

- **Principles invoked**: Unique count
- **Reinforcement ratio**: Depth of application
- **Missing principles**: Expected but not invoked
