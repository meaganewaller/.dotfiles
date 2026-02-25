---
name: weekly-review
description: Generate a weekly engineering review by aggregating dev-os-events, rendering charts, and producing staff-level insights + promotion-ready bullets.
disable-model-invocation: true
context: fork
agent: Explore
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(jq *)
  - Bash(python3 *)
  - Bash(bash ~/.claude/skills/weekly-review/scripts/run_weekly_review.sh)
---

# Weekly Engineering Review (Dev OS)

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

Output:

1. **Executive Summary** (3–6 sentences): interpret execution quality, risk, discipline.
2. **Friction Analysis**: pick top 1–2 friction domains, explain why they’re happening, and propose a deliberate practice plan.
3. **Architecture & Principles**: interpret which principles dominate and what that implies (strengths + blindspots).
4. **Discipline Flags**: call out large-change-without-tradeoff, reversals, dependency churn. Be direct.
5. **Promotion-Ready Impact Bullets**: 4–6 bullets; specific and measurable; grounded in patterns.
6. **Precision Moves**: exactly 3 moves for next week:
   - 1 architecture focus
   - 1 skill deepening focus
   - 1 leverage move (documentation/abstraction/thought leadership)

Then append your synthesized bullets and precision moves into REVIEW_DIR/review.md by rewriting those placeholder sections (keep the rest intact).
