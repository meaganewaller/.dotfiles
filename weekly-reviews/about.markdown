---
layout: page
title: About
permalink: /about/
---

# Weekly Engineering Reviews

This site publishes automated weekly engineering reviews generated from my development activity across all projects.

## What This Is

These reviews are powered by **Dev OS**, a personal telemetry system built on top of [Claude Code](https://claude.ai/claude-code). The system:

- **Observes** engineering patterns in real-time via hooks
- **Classifies** errors into a friction taxonomy for pattern detection
- **Documents** architectural decisions and tradeoffs
- **Synthesizes** staff-level insights at week's end

## The Pipeline

{% mermaid %}
flowchart LR
    A[Daily Work] --> B[Event Capture]
    B --> C[Weekly Review]
    C --> D[This Site]
{% endmermaid %}

Every Claude Code tool use triggers hooks that log structured events. At week's end, these events are aggregated, visualized, and synthesized into actionable insights.

**Learn more:** [How It Works](/how-it-works/)

## Documentation

| Page | Description |
|------|-------------|
| [How It Works](/how-it-works/) | System overview and architecture |
| [Data Capture](/data-capture/) | How hooks observe and log activity |
| [Friction Taxonomy](/friction-taxonomy/) | Error classification hierarchy |
| [Review Pipeline](/review-pipeline/) | How raw data becomes insights |
| [Hooks & Cues](/hooks-and-cues/) | Event-driven telemetry and guidance |
| [Event Schema](/event-schema/) | Structure of captured events |

## Why This Exists

Engineering work is often invisible. Features ship, bugs get fixed, but the patterns of how work gets done—the friction encountered, the decisions made, the reversals and recoveries—fade from memory.

This system creates a persistent record that surfaces:

- **Where time goes** - Which projects, what types of work
- **Where friction lives** - Recurring errors and skill gaps
- **What principles guide decisions** - Architectural patterns invoked
- **How skills evolve** - Week-over-week trends

It's a feedback loop for deliberate practice.

## Source

The Dev OS configuration lives in my dotfiles:

- **Repository**: [github.com/meaganewaller/.dotfiles](https://github.com/meaganewaller/.dotfiles)
- **Path**: `home/.claude/`
