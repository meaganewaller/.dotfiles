# Claude Code Configuration

Profile-aware Claude Code configuration with Dev OS telemetry system.

## Quick Start

```bash
# Install (uses DOTFILES_PROFILE, defaults to 'work')
mise run claude

# Or specify profile
mise run claude --profile=personal

# Dry run (preview changes)
mise run claude:dry-run
```

## Documentation

| Document | Audience | Description |
|----------|----------|-------------|
| [Hooks & Cues Overview](docs/hooks-and-cues/overview.md) | Contributors | How the telemetry and guidance systems work |
| [Telemetry Architecture](docs/hooks-and-cues/telemetry-architecture.md) | Contributors | Visual guide to event flow |
| [Workflow Scenarios](docs/hooks-and-cues/workflow-scenarios.md) | Contributors | How telemetry captures common activities |
| [Writing Hooks](docs/hooks-and-cues/writing-hooks.md) | Contributors | Create new event handlers |
| [Writing Cues](docs/hooks-and-cues/writing-cues.md) | Contributors | Create context-aware guidance |
| [Writing Skills](docs/skills/writing-skills.md) | Contributors | Create custom skills |
| [Troubleshooting](docs/troubleshooting.md) | Operators | Common issues and solutions |
| [Architecture Decisions](docs/architecture/README.md) | Contributors | ADRs for this system |
| [Governance](governance/README.md) | Auditors | Policy traceability |
| [Hooks Reference](hooks/README.md) | Contributors | Detailed hook documentation |
| [Skills Catalog](skills/README.md) | Users | Available skills |

## Directory Structure

```
home/.claude/
├── README.md               # This file (landing page)
├── install.sh              # Merges configs, links components
│
├── docs/                   # Structured documentation
│   ├── architecture/       # ADRs
│   ├── hooks-and-cues/     # System documentation
│   ├── skills/             # Skill authoring
│   └── troubleshooting.md
│
├── settings/               # Profile-merged settings
│   ├── common/             # Shared across profiles
│   └── {profile}/          # Profile overrides
│
├── hooks/                  # Dev OS telemetry hooks
├── skills/                 # Custom skills (16 total)
├── cues/                   # Context-aware guidance
├── agents/                 # Custom agent definitions
└── governance/             # Policy traceability
```

## Settings

Settings merge from `common/` + `{profile}/`:

```
common/*.jsonc  ──┐
                  ├──▶  ~/.claude/settings.json
{profile}/*.jsonc─┘
```

**Merge rules**: Arrays concatenate and dedupe. Objects deep merge. Internal state preserved.

```bash
# Add to common (all profiles)
vim settings/common/base.jsonc

# Add to specific profile
vim settings/work/overrides.jsonc

# Refresh
mise run claude:refresh
```

## Key Concepts

### Dev OS Telemetry

Hooks observe engineering patterns and emit structured events to `~/.claude/dev-os-events.jsonl`. The `/weekly-review` skill aggregates these for insights.

→ [Learn more](docs/hooks-and-cues/overview.md#hooks-dev-os-telemetry)

### Cues

Cues inject contextual guidance when triggers match prompts, commands, or files. They're "compiled policy" with governance traceability.

→ [Learn more](docs/hooks-and-cues/overview.md#cues-context-aware-guidance)

### Skills

16 custom skills for analysis, review, and workflow automation:

`abstraction-check` · `api-conventions` · `assumption-scan` · `complexity-audit` · `dependency-evaluator` · `design-review` · `experiment-design` · `friction-deep-dive` · `impact-narrative` · `mental-model` · `promotion-draft` · `refactor-safely` · `risk-audit` · `root-cause` · `tradeoff-memo` · `weekly-review`

→ [Full catalog](skills/README.md)

### Governance

Policy traceability via provenance metadata in cues:

```bash
dotfiles governance              # Coverage report
dotfiles governance --trace commit  # Trace a cue
dotfiles governance --lint       # Validate integrity
```

→ [Learn more](governance/README.md)

## Common Tasks

| Task | Command |
|------|---------|
| Refresh settings | `mise run claude:refresh` |
| Check hook health | `~/.claude/hooks/common/hook-health.sh` |
| Run weekly review | `/weekly-review` |
| Check governance | `dotfiles governance` |
| Debug issues | See [Troubleshooting](docs/troubleshooting.md) |
