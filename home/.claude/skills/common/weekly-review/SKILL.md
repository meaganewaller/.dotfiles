---
name: weekly-review
description: Generate a weekly engineering review by aggregating dev-os-events across ALL projects, rendering charts, and producing staff-level insights + promotion-ready bullets.
context: fork
agent: general-purpose
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Edit
  - Bash(jq *)
  - Bash(python3 *)
  - Bash(bash ~/.claude/skills/weekly-review/scripts/run_weekly_review.sh)
---

# Weekly Engineering Review (Dev OS)

This review aggregates data from **all projects** touched during the week, providing a holistic view of engineering activity across your entire workflow.

You MUST precompute stats and artifacts before analysis.

## Step 0 — Generate weekly artifacts

Run:

- !`bash ~/.claude/skills/weekly-review/scripts/run_weekly_review.sh`

This generates:
- summary.json
- review.md
- charts/
- index.html

Capture the printed directory path as REVIEW_DIR.

## Step 1 — Read artifacts

Read:
- REVIEW_DIR/summary.json
- REVIEW_DIR/review.md

## Step 2 — Produce staff-level synthesis

Analyze the data and prepare content for these sections:

1. **Executive Summary** (3–6 sentences): interpret execution quality, risk, discipline.
2. **Friction Analysis**: pick top 1–2 friction domains, explain why they’re happening, and propose a deliberate practice plan.
3. **Architecture & Principles**: interpret which principles dominate and what that implies (strengths + blindspots).
4. **Discipline Flags**: call out large-change-without-tradeoff, reversals, dependency churn. Be direct.
5. **Promotion-Ready Impact Bullets**: 4–6 bullets; specific and measurable; grounded in patterns.
6. **Precision Moves**: exactly 3 moves for next week:
   - 1 architecture focus
   - 1 skill deepening focus
   - 1 leverage move (documentation/abstraction/thought leadership)

## Step 3 — Update review.md

Use the **Edit tool** to replace each placeholder block in REVIEW_DIR/review.md.

Each placeholder is wrapped in HTML comments like:
```
<!-- PLACEHOLDER:NAME -->
_Placeholder text here._
<!-- END:NAME -->
```

Replace the **entire block** (including both comment markers and the placeholder text) with your content.

### Required edits (6 total):

1. **EXECUTIVE_SUMMARY** — Replace with your 3-6 sentence synthesis
2. **FRICTION_ANALYSIS** — Replace with your friction domain analysis and practice plan
3. **ARCHITECTURE_ANALYSIS** — Replace with your principles interpretation
4. **DISCIPLINE_FLAGS** — Replace with flags for large changes, reversals, churn
5. **IMPACT_BULLETS** — Replace with 4-6 promotion-ready bullets
6. **PRECISION_MOVES** — Replace with exactly 3 moves (architecture, skill, leverage)

### Example edit:

```
old_string: |
  <!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->
  _Claude will synthesize execution quality, risk, and discipline here._
  <!-- END:EXECUTIVE_SUMMARY -->

new_string: |
  This week demonstrated strong execution discipline with 45 successful writes...
```

You MUST use the Edit tool to modify the file. Do NOT skip this step or claim you cannot edit.
Do NOT output the content to the chat — write it directly to the file.

## Step 4 — Regenerate dashboard

After updating review.md, regenerate the HTML dashboard to include your synthesized content:

```bash
python3 ~/.claude/skills/weekly-review/scripts/render_dashboard.py REVIEW_DIR/summary.json
```

This updates index.html with the edited review content in the Review tab.
