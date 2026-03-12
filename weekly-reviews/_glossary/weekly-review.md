---
layout: glossary-term
term: Weekly Review
short: Automated synthesis of development insights
category: core
related:
  - dev-os
  - pipeline
  - aggregate
  - precision-move
aliases:
  - weekly reviews
  - /weekly-review
---

An automated synthesis of the past 7 days of development activity, including metrics, friction analysis, and actionable recommendations.

## What's Included

- **Executive Summary** - Overall assessment, wins, concerns
- **Execution Metrics** - Events, writes, failures, tests
- **Friction Analysis** - Top domains, root causes, practice recommendations
- **Architectural Thinking** - Principles invoked, blindspots
- **Discipline Flags** - Large changes, reversals, documentation gaps
- **Impact Bullets** - Promotion-ready accomplishment statements
- **Precision Moves** - Specific recommendations for next week

## Pipeline

The review is generated through four stages:

1. **aggregate.sh** - Process events into summary.json
2. **charts.py** - Generate visualizations
3. **render_md.sh** - Create markdown template
4. **AI Synthesis** - Fill analysis placeholders

## Invocation

```
/weekly-review
```

Or trigger via the weekly-review skill.
