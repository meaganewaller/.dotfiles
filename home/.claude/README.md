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

## Directory Structure

```
home/.claude/
├── install.sh              # Merges configs, links skills/hooks/agents
│
├── settings/               # Profile-merged settings (JSONC supported)
│   ├── common/             # Shared across all profiles
│   │   ├── base.jsonc      # Core preferences
│   │   ├── hooks.jsonc     # Hook definitions
│   │   └── permissions/    # Tool permissions
│   │       ├── directories.jsonc
│   │       └── skills.jsonc
│   ├── work/               # Work profile overrides
│   └── personal/           # Personal profile overrides
│
├── hooks/                  # Dev OS telemetry hooks
│   └── common/             # Event handlers (see Dev OS below)
│
├── skills/                 # Custom skills (see skills/README.md)
│   └── common/             # 16 skills
│
├── agents/                 # Custom agent definitions
│   └── *.md                # Agent markdown specs
│
├── docs/                   # Documentation, blog drafts
│   └── blog-drafts/
│
├── scripts/                # Helper scripts
└── *.manifest.json         # Agent manifests per profile
```

## Settings Merge

The install script merges JSONC files in order:

```
common/*.jsonc  ──┐
                  ├──▶  ~/.claude/settings.json
{profile}/*.jsonc─┘
```

### Merge Rules

1. **Arrays** (permissions.allow, etc.): Concatenated and deduplicated
2. **Objects**: Deep merged (profile overrides common)
3. **Internal state**: Preserved (numStartups, userID, projects, etc.)

### Adding Settings

```bash
# Add to common (all profiles)
vim home/.claude/settings/common/base.jsonc

# Add to specific profile
vim home/.claude/settings/work/overrides.jsonc

# Refresh
mise run claude:refresh
```

---

## Dev OS: Engineering Telemetry

Dev OS is a telemetry layer that observes engineering patterns and surfaces insights.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Claude Code Session                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐          │
│   │ PreToolUse  │   │ PostToolUse │   │ PostToolUseFailure  │          │
│   │ ─────────── │   │ ─────────── │   │ ─────────────────── │          │
│   │ layering    │   │ impact      │   │ skill-gap           │          │
│   │ guard       │   │ extractor   │   │ detector            │          │
│   │             │   │ large-diff  │   │                     │          │
│   │             │   │ escalator   │   │                     │          │
│   │             │   │ reversal    │   │                     │          │
│   │             │   │ detector    │   │                     │          │
│   │             │   │ tradeoff    │   │                     │          │
│   │             │   │ capture     │   │                     │          │
│   └─────────────┘   └─────────────┘   └─────────────────────┘          │
│                                                                         │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐          │
│   │SessionStart │   │    Stop     │   │   SubagentStop      │          │
│   │ ─────────── │   │ ─────────── │   │ ─────────────────── │          │
│   │ friction    │   │ test        │   │ tradeoff            │          │
│   │ escalator   │   │ blocker     │   │ extractor           │          │
│   │ context     │   │ tradeoff    │   │                     │          │
│   │ injector    │   │ blocker     │   │                     │          │
│   └─────────────┘   └─────────────┘   └─────────────────────┘          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                      ┌───────────────────────┐
                      │ ~/.claude/            │
                      │ dev-os-events.jsonl   │
                      │                       │
                      │ Append-only event     │
                      │ stream across all     │
                      │ projects & sessions   │
                      └───────────────────────┘
                                    │
                                    ▼
                      ┌───────────────────────┐
                      │   /weekly-review      │
                      │                       │
                      │ Aggregates events     │
                      │ Generates insights    │
                      │ Renders dashboard     │
                      └───────────────────────┘
```

### Event Types

| Event Type | Trigger | Payload |
|------------|---------|---------|
| `tool_write` | File created/edited | files, change_type, risk_level |
| `tool_failure` | Any tool error | domain, subdomain, hints, signals |
| `large_change` | Diff > 250 lines | file_path, line_count |
| `reversal` | Undoing recent work | reverted_file, reason |
| `decision_tradeoff` | Architectural decision | options, tradeoffs, principles |
| `test_run` | Test execution | pass/fail, test names |

### Friction Taxonomy

Tool failures are classified into domains:

```
Primary Domains:
├── syntax      - Parse errors, malformed input
├── type        - Type mismatches, inference failures
├── dependency  - Missing packages, version conflicts
├── permission  - Access denied, auth failures
├── network     - Connection, timeout, SSL errors
├── state       - File not found, resource limits
├── config      - Env vars, misconfiguration
├── testing     - Test failures, assertions
└── build       - Compilation, bundling errors
```

Each domain has subdomains (e.g., `state:file-not-found`, `state:resource-limit`).

### Hook Descriptions

#### PostToolUse Hooks

| Hook | Purpose |
|------|---------|
| `impact-extractor.sh` | Logs file writes with metadata |
| `large-diff-escalator.sh` | Flags changes >250 lines, creates tradeoff marker |
| `reversal-detector.sh` | Detects when recent work is undone |
| `tradeoff-capture.sh` | Marks tradeoffs as documented |
| `dependency-change-detector.sh` | Flags package.json/Gemfile changes |
| `async-test-runner.sh` | Runs tests in background after edits |

#### PostToolUseFailure Hooks

| Hook | Purpose |
|------|---------|
| `skill-gap-detector.sh` | Classifies errors into friction taxonomy |

#### SessionStart Hooks

| Hook | Purpose |
|------|---------|
| `friction-escalator.sh` | Surfaces repeated friction patterns |
| `session-context-injector.sh` | Injects project context |

#### Stop Hooks

| Hook | Purpose |
|------|---------|
| `hard-stop-test-blocker.sh` | Blocks stop if last test failed |
| `pending-tradeoff-blocker.sh` | Blocks stop if large changes undocumented |

#### Other Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `layering-guard.sh` | PreToolUse | Warns about layering violations |
| `task-gate.sh` | TaskCompleted | Task completion logging |
| `learning-suggestion-generator.sh` | SessionEnd | Suggests learning based on session |
| `pre-compact-snapshot.sh` | PreCompact | Saves context before compression |

### Discipline Enforcement

The system enforces engineering discipline:

#### Large Change Accountability

When a diff exceeds 250 lines:

1. `large-diff-escalator.sh` creates marker in `~/.claude/pending-tradeoffs/`
2. Shows directive: "Document tradeoffs before continuing"
3. At session end, `pending-tradeoff-blocker.sh` checks for uncaptured tradeoffs
4. **Blocks stop** if tradeoffs not documented

#### Friction Escalation

At session start, `friction-escalator.sh`:

1. Reads recent friction from `~/.claude/skill-friction-log.jsonl`
2. If domain has 3+ occurrences in 24h, surfaces it:
   ```
   Repeated friction in [state]: 15 hits.
   Subdomains: file-not-found(10) resource-limit(5).
   Hint: Use offset/limit for large files.
   ```

### Weekly Review

The `/weekly-review` skill aggregates all events:

```bash
# Run weekly review
/weekly-review
```

Generates:
- `summary.json` - Aggregated metrics by project
- `review.md` - Markdown report with placeholders
- `charts/` - Visualizations
- `index.html` - Interactive dashboard

The skill agent fills placeholders with:
- Executive summary
- Friction analysis
- Promotion-ready impact bullets
- Precision moves for next week

---

## Skills

See `skills/README.md` for the full catalog of 16 skills.

Quick list:
- `abstraction-check` - Evaluate if abstraction is justified
- `api-conventions` - API design principles
- `assumption-scan` - Surface hidden assumptions
- `complexity-audit` - Find accidental complexity
- `dependency-evaluator` - Assess third-party dependencies
- `design-review` - Review technical designs
- `experiment-design` - Design experiments with hypotheses
- `friction-deep-dive` - Analyze recurring friction
- `impact-narrative` - Translate work to business impact
- `mental-model` - Build understanding before modifying
- `promotion-draft` - Prepare promotion packets
- `refactor-safely` - Plan safe refactoring
- `risk-audit` - Audit for failure modes
- `root-cause` - 5 Whys analysis
- `tradeoff-memo` - Document architectural decisions
- `weekly-review` - Weekly engineering review

---

## Agents

Custom agents are defined in `agents/` and enabled via manifests:

```
common.manifest.json    # Agents for all profiles
work.manifest.json      # Work-specific agents
personal.manifest.json  # Personal agents
```

---

## Troubleshooting

### Settings not updating

```bash
# Re-run installer
mise run claude:refresh

# Check merged output
cat ~/.claude/settings.json | jq .
```

### Hooks not firing

```bash
# Check hook is executable
ls -la ~/.claude/hooks/PostToolUse/

# Check settings.json includes hooks
jq '.hooks' ~/.claude/settings.json
```

### Events not logging

```bash
# Check event file exists
tail -5 ~/.claude/dev-os-events.jsonl

# Check friction log
tail -5 ~/.claude/skill-friction-log.jsonl
```

### Weekly review fails

```bash
# Check dependencies
which jq python3

# Make scripts executable
chmod +x ~/.claude/skills/weekly-review/scripts/*.sh
chmod +x ~/.claude/skills/weekly-review/scripts/*.py
```

---

## Development

### Adding a Hook

1. Create script in `hooks/common/{EventType}/`
2. Make it executable: `chmod +x`
3. Add to `settings/common/hooks.jsonc`
4. Run `mise run claude:refresh`

### Adding a Skill

1. Create `skills/common/{name}/SKILL.md`
2. Add YAML frontmatter with name, description
3. Run `mise run claude:refresh`

### Testing Changes

```bash
# Dry run
mise run claude:dry-run

# Check what would be linked
./home/.claude/install.sh --dry-run
```
