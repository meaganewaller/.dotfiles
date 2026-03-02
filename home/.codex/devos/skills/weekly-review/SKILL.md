---
name: weekly-review
description: This skill should be used at the end of each week, when asking "how was my week?", "generate weekly review", "what did I accomplish?", or "/weekly-review". Aggregates dev-os-events across ALL projects, renders charts, and produces staff-level insights with promotion-ready bullets.
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
  - Bash(bash ~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh)
  - Bash(bash ~/.codex/devos/skills/weekly-review/scripts/finalize_review.sh *)
---

# Weekly Engineering Review (Dev OS)

This review aggregates data from **all projects** touched during the week, providing a holistic view of engineering activity across your entire workflow.

You MUST precompute stats and artifacts before analysis.

## Step 0 — Generate weekly artifacts

Run:

- !`WEEKLY_REVIEW_MODE=combined bash ~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh`
- !`WEEKLY_REVIEW_MODE=codex bash ~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh`
- !`WEEKLY_REVIEW_MODE=claude bash ~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh`

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

1. **Executive Summary**: A structured overview with these subsections:
   - **Overall Assessment** (1 sentence): High-level verdict on the week
   - **Key Wins** (2-3 bullets): What went well
   - **Concerns** (2-3 bullets): What needs attention
   - **Week Character** (1 sentence): The nature/theme of the work
2. **Friction Analysis**: pick top 1–2 friction domains, explain why they’re happening, and propose a deliberate practice plan. Use headers and bullet points.
3. **Architecture & Principles**: interpret which principles dominate and what that implies (strengths + blindspots). Use **Strengths:** and **Blindspots:** subsections.
4. **Discipline Flags**: call out large-change-without-tradeoff, reversals, dependency churn. Use bold headers for each flag type.
5. **Cue Engagement**: analyze which cues fired this week from summary.cue_engagement:
   - **Active cues**: which cues are actually providing guidance
   - **Trigger patterns**: prompt vs bash vs file triggers
   - **Dormant cues**: if unique_cues_fired is low relative to total cues, suggest reviewing cue triggers
   - **Hotspots**: frequently firing cues may indicate friction areas or well-designed guidance
6. **Promotion-Ready Impact Bullets**: 4–6 bullets; specific and measurable; grounded in patterns. Each bullet should start with a bold action verb.
6. **Precision Moves**: exactly 3 moves for next week, each with a bold title and 2-3 sentence explanation:
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

### Required edits (7 total):

1. **EXECUTIVE_SUMMARY** — Replace with your 3-6 sentence synthesis
2. **FRICTION_ANALYSIS** — Replace with your friction domain analysis and practice plan
3. **ARCHITECTURE_ANALYSIS** — Replace with your principles interpretation
4. **DISCIPLINE_FLAGS** — Replace with flags for large changes, reversals, churn
5. **CUE_ENGAGEMENT** — Replace with cue firing analysis and recommendations
6. **IMPACT_BULLETS** — Replace with 4-6 promotion-ready bullets
7. **PRECISION_MOVES** — Replace with exactly 3 moves (architecture, skill, leverage)

### Example edit:

```
old_string: |
  <!-- PLACEHOLDER:EXECUTIVE_SUMMARY -->
  _Codex will synthesize execution quality, risk, and discipline here._
  <!-- END:EXECUTIVE_SUMMARY -->

new_string: |
  **Overall Assessment:** Strong execution week with solid test coverage but elevated friction.

  **Key Wins:**
  - Delivered 45 successful writes across 3 projects
  - Maintained 92% test stability throughout infrastructure changes
  - Documented 4 architectural decisions with clear tradeoffs

  **Concerns:**
  - 38% failure rate indicates environmental friction
  - Only 2 of 8 large changes had documented tradeoffs
  - Resource-limit errors suggest need for chunked operations

  **Week Character:** Infrastructure investment week with expected turbulence.
```

You MUST use the Edit tool to modify the file. Do NOT skip this step or claim you cannot edit.
Do NOT output the content to the chat — write it directly to the file.

## Step 4 — Finalize and publish

After all edits are complete, run the finalize script to regenerate the dashboard and publish to Jekyll:

```bash
bash ~/.codex/devos/skills/weekly-review/scripts/finalize_review.sh REVIEW_DIR
```

This will:
- Regenerate the HTML dashboard with your synthesized content
- Copy the synthesized review.md content to the Jekyll post
- Update the summary.json in Jekyll's _data directory
- Copy charts to Jekyll assets
- Start the Jekyll server (if not already running)
- Open the review in your browser

**IMPORTANT**: You MUST run this step after filling all placeholders. Do not skip it.

## Troubleshooting

### No events found

```
Error: No events in the last 7 days
```

**Cause:** No configured event stream contains recent events.

**Fix:** Verify hooks are emitting events:
```bash
tail -5 ~/.codex/dev-os-events.jsonl
tail -5 ~/.claude/dev-os-events.jsonl
```

If empty, set explicit sources and retry:
```bash
CODEX_EVENT_STREAMS="$HOME/.codex/dev-os-events.jsonl:$HOME/.claude/dev-os-events.jsonl" \
bash ~/.codex/devos/skills/weekly-review/scripts/run_weekly_review.sh
```

---

### Script permission denied

```
Error: Permission denied: aggregate.sh
```

**Fix:** Make scripts executable:
```bash
chmod +x ~/.codex/devos/skills/weekly-review/scripts/*.sh
chmod +x ~/.codex/devos/skills/weekly-review/scripts/*.py
```

---

### Python dependencies missing

```
ModuleNotFoundError: No module named 'jinja2'
```

**Fix:** Install required packages:
```bash
pip3 install jinja2
```

---

### jq not found

```
Command not found: jq
```

**Fix:** Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

---

### Charts not rendering

**Cause:** `charts.py` requires matplotlib or the charts/ directory wasn't created.

**Fix:** Check charts directory exists and has content:
```bash
ls -la REVIEW_DIR/charts/
```

If empty, charts generation may have silently failed. Check for Python errors.

---

### Dashboard shows placeholder text

**Cause:** Step 3 (Edit placeholders) was skipped or Step 4 (Finalize and publish) wasn't run.

**Fix:**
1. Verify review.md has real content (not placeholder text)
2. Re-run: `python3 ~/.codex/devos/skills/weekly-review/scripts/render_dashboard.py REVIEW_DIR/summary.json`
