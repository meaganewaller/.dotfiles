# Writing Skills

> **Audience**: Contributors creating custom Claude Code skills

This guide covers how to create skills that extend Claude Code's capabilities.

## Quick Start

```bash
# 1. Create skill directory
mkdir -p skills/common/my-skill

# 2. Create skill definition
vim skills/common/my-skill/SKILL.md

# 3. Refresh configuration
mise run claude:refresh

# 4. Use the skill
# In Claude Code: /my-skill
```

## Skill Structure

```
skills/common/my-skill/
├── SKILL.md          # Required: skill definition
├── scripts/          # Optional: helper scripts
│   ├── analyze.sh
│   └── generate.py
└── templates/        # Optional: output templates
    └── report.md
```

## SKILL.md Format

```markdown
---
name: my-skill
description: One-line description shown in skill list
allowed_tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# My Skill

Detailed instructions for what this skill does and how Claude should execute it.

## When to Use

- Scenario 1
- Scenario 2

## Process

1. First step
2. Second step
3. Output format

## Output

Description of what the skill produces.
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | One-line description for listing |
| `allowed_tools` | No | Tools the skill can use (defaults to all) |
| `user_invocable` | No | If false, skill is internal only |

## Writing Effective Skills

### Be Specific

```markdown
## Process

1. Read `~/.claude/dev-os-events.jsonl` for the last 7 days
2. Group events by `event_type`
3. Calculate frequency and patterns
4. Generate markdown report with:
   - Summary statistics
   - Top friction areas
   - Recommendations
```

### Include Examples

```markdown
## Output Format

\`\`\`markdown
# Weekly Review - 2026-02-26

## Summary
- 47 tool_write events
- 12 tool_failure events
- 3 large_change events

## Friction Analysis
...
\`\`\`
```

### Reference Scripts

```markdown
## Process

1. Run the analysis script:
   \`\`\`bash
   ~/.claude/skills/my-skill/scripts/analyze.sh
   \`\`\`

2. Parse the JSON output

3. Fill the template at `~/.claude/skills/my-skill/templates/report.md`
```

## Helper Scripts

Place scripts in `scripts/` directory:

```bash
# skills/common/my-skill/scripts/analyze.sh
#!/usr/bin/env bash
set -euo pipefail

# Read events from last 7 days
SINCE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)

jq -s --arg since "$SINCE" '
  [.[] | select(.timestamp >= $since)]
  | group_by(.event_type)
  | map({type: .[0].event_type, count: length})
' ~/.claude/dev-os-events.jsonl
```

Make executable: `chmod +x skills/common/my-skill/scripts/analyze.sh`

## Skill Categories

### Analysis Skills

Read and analyze data, produce reports:
- `weekly-review` - Aggregate dev-os events
- `friction-deep-dive` - Analyze recurring friction
- `complexity-audit` - Find accidental complexity

### Review Skills

Examine code or designs:
- `design-review` - Review technical designs
- `assumption-scan` - Surface hidden assumptions
- `risk-audit` - Audit for failure modes

### Generation Skills

Create artifacts:
- `tradeoff-memo` - Document architectural decisions
- `promotion-draft` - Prepare promotion packets
- `impact-narrative` - Translate work to business impact

### Process Skills

Guide through workflows:
- `root-cause` - 5 Whys analysis
- `refactor-safely` - Plan safe refactoring
- `mental-model` - Build understanding before modifying

## Profile-Specific Skills

Place in profile directory for profile-specific skills:

```
skills/
├── common/           # All profiles
│   └── weekly-review/
├── work/             # Work profile only
│   └── gusto-specific/
└── personal/         # Personal profile only
    └── blog-helper/
```

## Testing Skills

```bash
# Refresh after changes
mise run claude:refresh

# Invoke in Claude Code
/my-skill

# Check skill is registered
jq '.skills' ~/.claude/settings.json
```

## Best Practices

1. **Single responsibility** - One skill, one job
2. **Clear output** - Describe exactly what's produced
3. **Idempotent** - Safe to run multiple times
4. **Self-contained** - Don't assume external state
5. **Documented** - Include when-to-use guidance

## Example: Complete Skill

```markdown
---
name: code-health
description: Analyze codebase health metrics
allowed_tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# Code Health Analysis

Analyzes codebase for health indicators and generates a report.

## When to Use

- Before major refactoring
- During code review of large changes
- Weekly health checks

## Process

1. Count lines of code by language:
   \`\`\`bash
   find . -name "*.rb" -o -name "*.ts" | xargs wc -l
   \`\`\`

2. Find large files (>500 lines):
   \`\`\`bash
   find . -name "*.rb" -exec wc -l {} \; | awk '$1 > 500'
   \`\`\`

3. Check for TODO/FIXME density:
   \`\`\`bash
   grep -r "TODO\|FIXME" --include="*.rb" | wc -l
   \`\`\`

4. Generate report with findings and recommendations

## Output

Markdown report with:
- Line count summary
- Large file list
- Technical debt indicators
- Recommendations
```

## Related Documentation

- [skills/README.md](../../skills/README.md) - Full skill catalog
- [Overview](../hooks-and-cues/overview.md) - System architecture
