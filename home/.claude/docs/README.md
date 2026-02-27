# Documentation

Structured documentation for the Claude Code configuration system.

## By Audience

| You want to... | Start here |
|----------------|------------|
| Understand why decisions were made | [Architecture Decision Records](architecture/) |
| Write or modify hooks | [Writing Hooks](hooks-and-cues/writing-hooks.md) |
| Create or extend cues | [Writing Cues](hooks-and-cues/writing-cues.md) |
| Build a new skill | [Writing Skills](skills/writing-skills.md) |
| Fix something broken | [Troubleshooting](troubleshooting.md) |
| Understand the telemetry system | [Telemetry Architecture](hooks-and-cues/telemetry-architecture.md) |

## Directory Structure

```
docs/
├── architecture/           # ADRs - "why did we do it this way?"
│   ├── 0001-*.md          # Documentation layer architecture
│   ├── 0002-*.md          # Tradeoff gate pattern
│   └── 0003-*.md          # Principle surfacing architecture
│
├── hooks-and-cues/        # Hook and cue system documentation
│   ├── overview.md        # How the system works
│   ├── writing-hooks.md   # Creating new hooks
│   ├── writing-cues.md    # Creating new cues
│   ├── telemetry-architecture.md  # Event system design
│   └── workflow-scenarios.md      # Common workflows
│
├── skills/                # Skill system documentation
│   └── writing-skills.md  # Creating new skills
│
├── blog-drafts/           # Blog posts in progress
│   ├── dev-os-claude-configuration.md
│   └── tradeoff-gate-pattern.md
│
└── troubleshooting.md     # Common issues and solutions
```

## Content Principles

Per [ADR-0001](architecture/0001-documentation-layer-architecture.md):

1. **Single source of truth** - Each concept lives in exactly one file
2. **Link, don't duplicate** - Reference via relative links
3. **Audience-appropriate depth** - Landing pages summarize, docs elaborate
4. **Implementation stays with code** - Hook/cue behavior docs live near implementations

## Related Locations

| Location | Content |
|----------|---------|
| [`../README.md`](../README.md) | System overview and quick start |
| [`../governance/`](../governance/) | Policies and compliance tooling |
| [`../principles/`](../principles/) | Engineering principles reference |
| [`../hooks/README.md`](../hooks/README.md) | Hook implementation details |
| [`../cues/`](../cues/) | Cue definitions |
| [`../skills/`](../skills/) | Skill implementations |
