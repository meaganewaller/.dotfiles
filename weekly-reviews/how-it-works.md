---
layout: page
title: How It Works
permalink: /how-it-works/
---

# How Dev OS Works

This site publishes automated weekly engineering reviews generated from my development activity. The system observes patterns in real-time and synthesizes insights at the end of each week.

## The Big Picture

Development activity flows through three stages:

{% mermaid %}
flowchart TD
    subgraph Daily["Daily Work"]
        A1[Edit files]
        A2[Run tests]
        A3[Fix errors]
        A4[Make decisions]
    end
    subgraph Capture["Event Capture"]
        B1[Hooks observe]
        B2[Log events]
        B3[Classify]
        B4[Store data]
    end
    subgraph Review["Weekly Review"]
        C1[Aggregate]
        C2[Analyze]
        C3[Synthesize]
        C4[Publish]
    end
    Daily --> Capture --> Review
{% endmermaid %}

## Component Overview

| Component | Purpose | Documentation |
|-----------|---------|---------------|
| **Hooks** | Observe tool usage, emit events | [Data Capture](/data-capture/) |
| **Cues** | Inject contextual guidance | [Hooks & Cues](/hooks-and-cues/) |
| **Event Log** | Central storage for all events | [Event Schema](/event-schema/) |
| **Skills** | Reusable analysis workflows | [Review Pipeline](/review-pipeline/) |
| **Friction Taxonomy** | Error classification system | [Friction Taxonomy](/friction-taxonomy/) |

## Data Flow

### 1. Event Capture

Every Claude Code tool use triggers hooks that observe and log activity:

{% mermaid %}
flowchart TD
    A[You edit a file] --> B[PostToolUse hook fires]
    B --> C[impact-extractor classifies]
    C --> D[(dev-os-events.jsonl)]
{% endmermaid %}

### 2. Storage

All events flow to a central log file:

```
~/.claude/
├── dev-os-events.jsonl    ◀── All events
├── impact-log.jsonl       ◀── File changes
├── skill-friction-log.jsonl ◀── Errors
└── reviews/               ◀── Weekly reports
```

### 3. Weekly Synthesis

The `/weekly-review` skill runs a four-stage pipeline:

```
aggregate.sh ──▶ charts.py ──▶ render_md.sh ──▶ AI synthesis
     │              │              │                │
     ▼              ▼              ▼                ▼
summary.json    *.png charts   review.md     Final analysis
```

## Key Concepts

### Events

Everything that happens during a coding session becomes an event:

- **tool_write** - File created or edited
- **tool_failure** - An error occurred
- **large_change** - Diff exceeded 250 lines
- **reversal** - Recent work was undone
- **decision_tradeoff** - Architectural decision documented
- **test_run** - Tests executed
- **session_duration** - Session length and archetype tracking
- **session_health** - Composite quality metrics at compaction
- **principle_activated** - First invocation of a principle
- **principle_reinforced** - Active principle re-surfaced before write
- **domain_modeling** - Upfront design work detected

See [Event Schema](/event-schema/) for complete payload documentation.

### Friction

Tool failures are classified into domains to identify patterns:

- **state** - File not found, resource limits
- **syntax** - Parse errors
- **dependency** - Missing packages
- **type** - Type mismatches
- **permission** - Access denied

See [Friction Taxonomy](/friction-taxonomy/) for the complete hierarchy.

### Session Archetypes

Sessions are classified by duration to provide appropriate guidance:

| Archetype | Duration | Friction Risk |
|-----------|----------|---------------|
| **Sprint** | <30 min | Low |
| **Flow** | 30-120 min | Medium |
| **Marathon** | >120 min | High |

Longer sessions correlate with more reversals and compaction pressure. See [Session Archetype](/glossary/session-archetype/) for details.

### Principles

Architectural principles are tracked through two phases:

1. **Activation** - First mention of a principle (e.g., "model-first")
2. **Reinforcement** - Re-surfacing before relevant write operations

This helps distinguish between principles that are merely mentioned vs. those that guide decisions through ambiguity. See [Principle Activation](/glossary/principle-activation/).

### Hooks

Shell scripts that run in response to Claude Code events:

- **Observation hooks** log what happens (PostToolUse)
- **Enforcement hooks** block actions when conditions aren't met (Stop)
- **Injection hooks** add context to the session (SessionStart)

See [Data Capture](/data-capture/) for implementation details.

### Cues

Contextual guidance injected when triggers match:

```yaml
---
pattern: commit|push
---
# Commit Cue

- Use conventional commit format
- Sign commits with GPG
```

See [Hooks & Cues](/hooks-and-cues/) for how cues work.

## Why This Exists

Engineering work is often invisible. Features ship, bugs get fixed, but the patterns of how work gets done fade from memory.

This system creates a persistent record that surfaces:

- **Where time goes** - Which projects, what types of work
- **Where friction lives** - Recurring errors, skill gaps
- **What principles guide decisions** - Architectural patterns invoked
- **How skills evolve** - Week-over-week trends

It's a feedback loop for deliberate practice.

## Source Code

The configuration lives in my dotfiles:

- **Repository**: [github.com/meaganewaller/.dotfiles](https://github.com/meaganewaller/.dotfiles)
- **Path**: `home/.claude/`

Key directories:
- `hooks/` - Event handlers
- `cues/` - Contextual guidance
- `skills/` - Analysis workflows
- `docs/` - System documentation
