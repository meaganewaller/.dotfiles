---
layout: page
title: Review Pipeline
permalink: /review-pipeline/
updated_at: 2026-03-10
---

# The Weekly Review Pipeline

How raw events become staff-level insights.

## Pipeline Overview

The `/weekly-review` skill runs `run_weekly_review.sh`, which orchestrates five stages before AI synthesis:

{% mermaid %}
flowchart TD
    subgraph S1["Stage 1: Aggregate"]
        A1[(dev-os-events.jsonl)] --> A2[aggregate.sh]
        A3[(decision-journal/)] --> A2
        A2 --> A4[summary.json]
        A2 --> A5[Jekyll data file]
    end
    subgraph S2["Stage 2: Visualize"]
        B1[summary.json] --> B2[charts.py]
        B2 --> B3[charts/*.png]
    end
    subgraph S3["Stage 3: Template"]
        C1[summary.json] --> C2[render_md.sh]
        C2 --> C3[review.md]
    end
    subgraph S4["Stage 4: Dashboard"]
        D1[summary.json] --> D2[render_dashboard.py]
        D3[review.md] --> D2
        D2 --> D4[index.html]
    end
    subgraph S5["Stage 5: AI Synthesis"]
        E1[review.md] --> E2[Claude]
        E2 --> E3[Filled placeholders]
    end
    subgraph S6["Stage 6: Publish"]
        F1[review.md] --> F2[publish_to_jekyll.sh]
        F3[charts/] --> F2
        F2 --> F4[Jekyll site]
    end
    S1 --> S2 --> S3 --> S4 --> S5 --> S6
{% endmermaid %}

Scripts live in `~/.claude/skills/weekly-review/scripts/`.

## Stage 1: Aggregate

`aggregate.sh` processes multiple data sources into a comprehensive summary.

### Inputs

| Source | Purpose |
|--------|---------|
| `~/.claude/dev-os-events.jsonl` | Primary event stream |
| `~/.claude/decision-journal/*.md` | Tradeoff documentation |
| `~/.claude/projects/` | Session-to-project mapping |

### Processing

The script:
1. Computes Monday-based week boundaries (UTC)
2. Filters events from the last 7 days
3. Maps sessions to projects via directory structure
4. Aggregates per-project metrics
5. Reads decision journal files for tradeoff data
6. Collects friction by domain/subdomain
7. Tracks cue engagement (fires, triggers)
8. Tracks session duration by category
9. Tracks skill invocations
10. Tracks context compaction events
11. Publishes summary to Jekyll `_data/dev_os/`

### Output Schema (v1.0.0)

`summary.json`:

```json
{
  "schema_version": "1.0.0",
  "week": {
    "start": "2026-03-03",
    "end": "2026-03-09",
    "generated_at": "2026-03-10T15:30:00Z"
  },
  "totals": {
    "events": 1259,
    "sessions": 45,
    "projects_touched": 3,
    "writes": 541,
    "failures": 568,
    "large_changes": 13,
    "reversals": 2,
    "decisions_documented": 5,
    "decisions_from_journal": 3,
    "decisions_from_events": 2,
    "test_runs": 116,
    "dependency_changes": 4,
    "files_modified": 87
  },
  "derived_metrics": {
    "failure_rate": 0.4512,
    "test_stability_rate": 0.85,
    "test_runs_passed": 99,
    "test_counts": {
      "passed": 450,
      "failed": 12,
      "skipped": 5,
      "total": 467
    }
  },
  "projects": [
    {
      "project": "dotfiles",
      "events": 676,
      "sessions": 20,
      "writes": 329,
      "failures": 327,
      "tradeoffs": 2,
      "large_changes": 5,
      "reversals": 1
    }
  ],
  "events_by_type": { "tool_write": 541, "tool_failure": 568 },
  "top_friction_domains": [
    { "domain": "state", "count": 511 }
  ],
  "top_friction_subdomains": [
    { "subdomain": "state:file-not-found", "count": 232 }
  ],
  "top_principles_invoked": [
    { "principle": "model-first", "count": 3 }
  ],
  "decisions": {
    "from_journal": [
      {
        "file": "2026-03-05-template-context.md",
        "date": "2026-03-05",
        "summary": "Extract ERB conditionals to testable POROs",
        "project": ".dotfiles",
        "source": "auto-capture",
        "tradeoffs_count": 3,
        "principles_count": 2
      }
    ],
    "capture_sources": [["auto-capture", 2], ["manual", 1]]
  },
  "cue_engagement": {
    "total_fires": 45,
    "unique_cues_fired": 8,
    "by_cue": [{ "cue": "file-verification", "count": 12 }],
    "by_trigger": [{ "trigger": "pattern", "count": 30 }]
  },
  "session_duration": {
    "sessions_tracked": 25,
    "total_minutes": 890,
    "average_minutes": 35.6,
    "median_minutes": 28,
    "longest_session": 145,
    "by_category": [
      { "category": "short", "count": 10 },
      { "category": "medium", "count": 8 },
      { "category": "long", "count": 5 },
      { "category": "marathon", "count": 2 }
    ],
    "by_project": [
      { "project": "dotfiles", "sessions": 15, "avg_minutes": 42.3 }
    ]
  },
  "skill_usage": {
    "total_invocations": 23,
    "unique_skills": 5,
    "by_skill": [{ "skill": "weekly-review", "count": 3 }]
  },
  "context_compaction": {
    "total_compactions": 8,
    "sessions_with_compaction": 4,
    "avg_compactions_per_session": 2.0,
    "total_bytes_compacted": 450000,
    "by_project": [
      { "project": "dotfiles", "compactions": 5 }
    ]
  },
  "top_skills_used": [{ "skill": "refactor", "count": 15 }],
  "top_files_modified": ["path/to/file.rb"]
}
```

## Stage 2: Visualize

`charts.py` generates bar charts using matplotlib (optional - skipped if not installed).

### Charts Generated

| Chart | Data Source | Purpose |
|-------|-------------|---------|
| `events_by_type.png` | `events_by_type` | Activity distribution |
| `friction_domains.png` | `top_friction_domains` | Error categories |
| `principles_invoked.png` | `top_principles_invoked` | Architectural thinking |

{% mermaid %}
flowchart LR
    A[summary.json] --> B[charts.py]
    B --> C[events_by_type.png]
    B --> D[friction_domains.png]
    B --> E[principles_invoked.png]
{% endmermaid %}

### Output

Charts saved to `~/.claude/reviews/week-of-YYYY-MM-DD/charts/`

## Stage 3: Template

`render_md.sh` generates the review markdown with data and placeholders.

### Template Sections

| Section | Content | AI Fills |
|---------|---------|----------|
| 📝 Executive Summary | Placeholder | ✓ |
| 📊 Execution Metrics | Overview table + per-project breakdown | |
| 🔁 Repeated Friction | Domain/subdomain lists | ✓ Analysis |
| 🧠 Architectural Thinking | Principles + skills lists | ✓ Analysis |
| ⚠️ Discipline Flags | Placeholder | ✓ |
| 🎯 Cue Engagement | Stats + by_cue/by_trigger lists | ✓ Analysis |
| 📈 Charts | Image links (if generated) | |
| 🚀 Impact Bullets | Placeholder | ✓ |
| 🎯 Precision Moves | Placeholder | ✓ |

### Placeholder Format

Placeholders use HTML comments for clean parsing:

```markdown
<!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->
_Claude will synthesize execution quality, risk, and discipline here._
<!-- END:EXECUTIVE_SUMMARY -->
```

### Per-Project Table

```markdown
| Project | Events | Sessions | Writes | Failures | Tradeoffs |
|---------|--------|----------|--------|----------|-----------|
| dotfiles | 676 | 20 | 329 | 327 | 2 |
| pull | 522 | 15 | 198 | 212 | 1 |
```

### Output

`review.md` with metrics filled in and `<!-- PLACEHOLDER:* -->` markers for AI synthesis.

## Stage 4: Dashboard

`render_dashboard.py` generates an interactive HTML dashboard with three tabs.

### Dashboard Tab

{% mermaid %}
flowchart LR
    subgraph Metrics
        A[Projects]
        B[Files Modified]
        C[Writes]
        D[Failures]
        E[Tradeoffs]
        F[Reversals]
        G[Test Stability]
    end
    subgraph Tables
        H[Per-Project Activity]
    end
    subgraph Lists
        I[Friction by Domain]
        J[Friction by Subdomain]
        K[Principles Invoked]
        L[Skills Demonstrated]
        M[Recent Files]
    end
    subgraph Charts
        N[Event Distribution]
        O[Friction Trends]
        P[Principles Heat]
    end
{% endmermaid %}

### Review Tab

Renders `review.md` as styled HTML with:
- Readable typography (dark theme)
- Styled lists with accent borders
- Formatted tables and code blocks
- Placeholder comments stripped

### Data Tab

Syntax-highlighted view of `summary.json` for debugging/exploration.

### Output

`index.html` - standalone dashboard viewable locally via `file://` or served via Jekyll.

---

## Stage 5: AI Synthesis

Claude reads the summary and template, then fills in the six placeholders:

### EXECUTIVE_SUMMARY

Staff-level assessment including:
- Overall characterization of the week
- Key wins (3-4 bullets)
- Concerns (3-4 bullets)
- Week character summary

### FRICTION_ANALYSIS

Deep analysis of top friction domains:
- Root cause identification
- Pattern recognition across sessions
- Deliberate practice recommendations
- Links to [Friction Taxonomy](/friction-taxonomy/) for context

### ARCHITECTURE_ANALYSIS

Assessment of architectural thinking:
- Principle distribution analysis
- Strengths demonstrated
- Blindspots identified
- Recommendations for deeper engagement

### DISCIPLINE_FLAGS

Evaluation of engineering discipline:
- Large changes without tradeoff documentation
- Reversal patterns (wasted effort)
- Dependency churn assessment
- Test stability concerns

### CUE_ENGAGEMENT

Analysis of cue engagement:
- Which cues fired most frequently
- Trigger type distribution (pattern, file, command)
- Dormant cue assessment
- Recommendations for cue refinement

### IMPACT_BULLETS

Promotion-ready impact bullets (4-6):
- Action verb + deliverable format
- Quantified where possible
- Business-relevant framing
- Grounded in actual events from the week

### PRECISION_MOVES

Three actionable recommendations for next week:
1. **Architecture Focus** - System design improvement
2. **Skill Deepening** - Deliberate practice target based on friction
3. **Leverage Move** - Multiplier action

---

## Stage 6: Publish

`publish_to_jekyll.sh` publishes the synthesized review to the Jekyll site.

### Actions

1. Copy `summary.json` to `_data/dev_os/YYYY-MM-DD-summary.json`
2. Merge `review.md` into `_reviews/YYYY-MM-DD-weekly-review.md` (preserving frontmatter)
3. Copy charts to `assets/charts/YYYY-MM-DD/`
4. Start Jekyll server (optional)
5. Open review in browser

### Jekyll Integration

```
weekly-reviews/
├── _data/
│   └── dev_os/
│       └── 2026-03-03-summary.json
├── _reviews/
│   └── 2026-03-03-weekly-review.md
└── assets/
    └── charts/
        └── 2026-03-03/
            ├── events_by_type.png
            ├── friction_domains.png
            └── principles_invoked.png
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `JEKYLL_ROOT` | `~/github/meaganewaller/weekly-reviews` | Jekyll site root |
| `JEKYLL_PORT` | `4000` | Local server port |
| `SKIP_SERVER` | `0` | Set to `1` to skip server start |

## Final Output

The completed review includes:

| Output | Location | Format |
|--------|----------|--------|
| Local summary | `~/.claude/reviews/week-of-*/summary.json` | JSON |
| Local review | `~/.claude/reviews/week-of-*/review.md` | Markdown |
| Local dashboard | `~/.claude/reviews/week-of-*/index.html` | HTML |
| Local charts | `~/.claude/reviews/week-of-*/charts/*.png` | PNG |
| Jekyll summary | `_data/dev_os/*-summary.json` | JSON |
| Jekyll review | `_reviews/*-weekly-review.md` | Jekyll post |
| Jekyll charts | `assets/charts/*/*.png` | PNG |

### Review Content

- **Execution Metrics** - Quantified activity per project
- **Friction Analysis** - Where time was lost and why
- **Architectural Assessment** - Design thinking quality
- **Cue Engagement** - How guidance system performed
- **Discipline Flags** - Process compliance issues
- **Impact Framing** - Promotion-ready narrative
- **Precision Moves** - Concrete next steps

## Pipeline Timing

| Stage | Duration | Notes |
|-------|----------|-------|
| Aggregate | ~3s | Python processing + journal parsing |
| Charts | ~8s | matplotlib (skipped if not installed) |
| Template | ~1s | bash + jq |
| Dashboard | ~2s | Python HTML generation |
| AI Synthesis | ~60s | Claude fills placeholders |
| Publish | ~5s | File copy + optional server start |

Total: ~80 seconds for a full week's review (excluding server startup).

## Customization

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `JEKYLL_ROOT` | `~/github/meaganewaller/weekly-reviews` | Jekyll site location |
| `JEKYLL_PORT` | `4000` | Local server port |
| `SKIP_SERVER` | `0` | Skip Jekyll server on publish |

### Chart Styling

Edit `charts.py` to modify:
- Color schemes
- Figure sizes (default dpi=160)
- Label formatting
- Number of items shown (default: top 12)

### Template Sections

Edit `render_md.sh` to add/remove sections or change structure.

### Dashboard Styling

Edit `render_dashboard.py` to modify:
- CSS variables (colors, spacing)
- Tab layout
- Metric card styling
- Markdown-to-HTML conversion

### Decision Journal Integration

Decision journal files in `~/.claude/decision-journal/` are automatically included if:
- Filename starts with date (YYYY-MM-DD)
- Date falls within the review week
- File contains standard sections (Decision Summary, Trade-offs, etc.)

### Schema Version

The summary schema is versioned (`schema_version: "1.0.0"`). Update consumers when schema changes.

---

Previous: [Friction Taxonomy](/friction-taxonomy/) | Next: [Hooks & Cues](/hooks-and-cues/)
