---
layout: glossary-term
term: Skill
short: Reusable procedural guidance for specific tasks
category: guidance
related:
  - cue
  - hook
  - deliberate-practice
aliases:
  - skills
  - skill definition
---

Reusable procedural guidance that can be invoked explicitly. Unlike cues (which trigger automatically), skills are called intentionally via `/skill-name` syntax.

## Skills vs Cues

| Aspect | Skill | Cue |
|--------|-------|-----|
| Invocation | Explicit (`/standup`) | Automatic (pattern match) |
| Purpose | "How do I do X?" | "Remember Y when doing Z" |
| Length | Longer, step-by-step | Shorter, checklist/reminder |
| Scope | Task-focused | Context-focused |

## Skill Structure

Skills live in `~/.claude/skills/<scope>/<name>/`:

```
skills/
├── common/                    # Cross-project skills
│   ├── standup/
│   │   └── SKILL.md
│   ├── code-review/
│   │   └── SKILL.md
│   └── debug-session/
│       └── SKILL.md
└── project/                   # Project-specific skills
    └── deploy/
        └── SKILL.md
```

## SKILL.md Format

```yaml
---
name: code-review
description: This skill should be used when reviewing code...
---

# Code Review

## Steps

1. **Correctness**: Does it do what it claims?
2. **Security**: Any vulnerabilities?
3. **Performance**: Any bottlenecks?
4. **Maintainability**: Is it readable?

## Checklist

- [ ] Tests cover the change
- [ ] No secrets in code
- [ ] Error cases handled
```

## Built-in Skills

| Skill | Purpose |
|-------|---------|
| `/standup` | Generate daily standup from events |
| `/code-review` | Structured code review |
| `/debug-session` | Hypothesis-driven debugging |
| `/commit` | Guided commit workflow |
| `/weekly-review` | Aggregate week's telemetry |

## Pattern: ADR to Skill

Decisions significant enough for an ADR often deserve a skill if they'll be applied repeatedly:

- **ADR** answers "Why this pattern?"
- **Skill** answers "How do I use it?"

Example: ADR-0007 (TemplateContext) explains the decision; the `template-context` skill provides step-by-step implementation guidance.

## Telemetry

Skill invocations are tracked:

```json
{
  "event_type": "skill_invoked",
  "payload": {
    "skill_name": "code-review",
    "invocation_method": "slash_command"
  }
}
```

## In Weekly Reviews

- **Skills invoked**: Count and distribution
- **Skill gaps**: Areas where skills might help but don't exist
- **Skill effectiveness**: Correlation with outcomes (requires manual tagging)

## Creating New Skills

1. Identify a repeatable task with consistent steps
2. Create `~/.claude/skills/common/<name>/SKILL.md`
3. Add description for semantic matching
4. Document steps, checklists, and examples
5. Cross-reference related ADRs or principles

## See Also

- `~/.claude/skills/` - Skill definitions
- `/help` - List available skills
