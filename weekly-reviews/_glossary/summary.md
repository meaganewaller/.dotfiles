---
layout: glossary-term
term: Summary
short: JSON file containing aggregated weekly metrics
category: output
related:
  - aggregate
  - pipeline
  - weekly-review
aliases:
  - summary.json
---

A JSON file containing aggregated metrics from the past week, used to generate charts and the review template.

## Location

```
~/.claude/reviews/week-of-YYYY-MM-DD/summary.json
```

## Structure

```json
{
  "window": {
    "start": "2026-02-20",
    "end": "2026-02-27",
    "generated_at": "2026-02-27T15:30:00Z"
  },
  "metrics": {
    "total_events": 1259,
    "writes": 541,
    "failures": 568,
    "large_changes": 13,
    "reversals": 2,
    "decisions": 2,
    "test_runs": 116,
    "test_passes": 50
  },
  "projects": [
    {"project": "dotfiles", "events": 676, "writes": 329}
  ],
  "friction": {
    "by_domain": {"state": 511, "dependency": 3},
    "by_subdomain": {"state:file-not-found": 232}
  },
  "principles": {
    "explicit over implicit": 1,
    "convention over configuration": 1
  },
  "files_modified": ["path/to/file.rb"]
}
```

## Usage

The summary feeds into:

- **charts.py** - Visualization generation
- **render_md.sh** - Template population
- **Review layout** - Dashboard metrics display
