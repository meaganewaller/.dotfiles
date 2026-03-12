---
layout: glossary-term
term: Pipeline
short: Four-stage process generating weekly reviews
category: core
related:
  - weekly-review
  - aggregate
  - summary
aliases:
  - review pipeline
---

The four-stage process that transforms raw events into weekly insights.

## Stages

### 1. Aggregate (`aggregate.sh`)

Processes raw events and computes metrics:

- Filters last 7 days
- Groups by event type
- Counts sessions and projects
- Aggregates friction by domain

**Output:** `summary.json`

### 2. Visualize (`charts.py`)

Generates visual representations:

- Events by type bar chart
- Friction domains pie chart
- Principles invoked chart

**Output:** `*.png` files

### 3. Template (`render_md.sh`)

Creates markdown with placeholders:

- Fills in metrics from summary
- Leaves `{{PLACEHOLDER}}` markers for AI

**Output:** `review.md` template

### 4. Synthesize (AI)

Claude fills analysis placeholders:

- Executive summary
- Friction analysis
- Impact bullets
- Precision moves

**Output:** Final review

## Timing

| Stage | Duration |
|-------|----------|
| Aggregate | ~5s |
| Visualize | ~10s |
| Template | ~2s |
| Synthesis | ~60s |

**Total:** ~80 seconds
