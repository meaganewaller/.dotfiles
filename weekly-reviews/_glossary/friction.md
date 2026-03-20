---
layout: glossary-term
term: Friction
short: Classified tool failures and errors
category: analysis
related:
  - friction-taxonomy
  - domain
  - subdomain
  - skill-gap
aliases:
  - friction log
  - tool failure
---

Tool failures or errors encountered during development, classified into domains for pattern detection.

## Why Track Friction?

Friction patterns reveal:

- **Skill gaps** - Areas needing deliberate practice
- **Environmental issues** - Tooling or config problems
- **Process problems** - Workflow inefficiencies

## Classification

Each friction event is classified with:

- **Domain** - Top-level category (state, syntax, dependency, etc.)
- **Subdomain** - Specific type (file-not-found, resource-limit, etc.)
- **Hints** - Suggestions for resolution

## Example Event

```json
{
  "event_type": "tool_failure",
  "payload": {
    "domain": "state",
    "subdomain": "file-not-found",
    "hints": ["Check if file exists before reading"]
  }
}
```

## Escalation

When the same friction domain appears 3+ times, it's surfaced as a warning at session start.
