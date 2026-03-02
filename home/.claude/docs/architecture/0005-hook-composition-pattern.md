---
status: accepted
date: 2026-03-02
deciders: [meaganewaller]
---

# 5. Hook Composition Pattern

## Status

Accepted

## Context

Claude Code hooks are shell scripts that execute at specific lifecycle events (PreToolUse, PostToolUse, SessionStart, Stop, etc.). As the number of hooks grows, we face challenges:

1. **Code duplication** - Common patterns (path validation, event emission) repeated in every hook
2. **Observability** - No visibility into which hooks run, how long they take, or why they fail
3. **Organization** - Flat directory makes it hard to find hooks by purpose
4. **Consistency** - Different hooks use different patterns for the same operations

We need a composition pattern that promotes reuse, provides observability, and maintains organization as the system scales.

## Decision

We will organize hooks using a layered composition pattern with shared utilities and health monitoring.

### Directory Structure

```
home/.claude/hooks/
├── common/                           # Shared implementation (source of truth)
│   ├── validate-path.sh              # Shared utilities library
│   ├── dev-os-emit.sh                # Event emission script
│   ├── hook-health.sh                # Health aggregation script
│   ├── match-cues.sh                 # Cue matching logic
│   ├── show-cue.sh                   # Cue rendering
│   ├── semantic-match.sh             # Semantic matching for cues
│   │
│   ├── PreToolUse/                   # Hooks by event type
│   │   ├── layering-guard.sh
│   │   ├── large-file-guard.sh
│   │   └── cue-injector-file.sh
│   ├── PostToolUse/
│   │   ├── impact-extractor.sh
│   │   ├── reversal-detector.sh
│   │   └── skill-usage-tracker.sh
│   ├── PostToolUseFailure/
│   │   └── skill-gap-detector.sh
│   ├── SessionStart/
│   │   ├── session-start-tracker.sh
│   │   └── friction-escalator.sh
│   ├── SessionEnd/
│   │   └── session-end-tracker.sh
│   ├── Stop/
│   │   └── tradeoff-context-prep.sh
│   └── PreCompact/
│       └── context-compact-tracker.sh
│
└── README.md                         # Hook documentation
```

The `common/` directory is the source of truth. Symlinks in `~/.claude/hooks/<Event>/` point to these implementations.

### Shared Utilities (validate-path.sh)

All hooks source a shared library that provides:

**Path Constants:**
```bash
export CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
export CLAUDE_EVENTS_LOG="$CLAUDE_HOME/dev-os-events.jsonl"
export DEV_OS_EMIT="$CLAUDE_HOME/hooks/dev-os-emit.sh"
```

**Validation Functions:**
```bash
validate_file_exists "/path/to/file"     # Returns 0/1, never exits
validate_file_readable "/path/to/file"
validate_dir_exists "/path/to/dir"
```

**Ensure Functions:**
```bash
ensure_dir_exists "/path/to/dir"         # Creates if missing
ensure_file_exists "/path/to/file"       # Creates with parent dirs
```

**Safe Operations:**
```bash
safe_tail "/path/to/file" 10             # Returns empty if missing
safe_append "/path/to/file" "data"       # Creates if missing
safe_emit "event_type" '{"key":"value"}' # Handles missing emit script
```

**Resource Guards:**
```bash
guard_diff_size "$diff" 5000             # Truncates large diffs
guard_file_size "/path" 1024             # Checks KB limit
guard_log_size "$log" 50                 # Checks MB limit
```

### Hook Registration and Health Monitoring

Every hook registers itself for observability:

```bash
#!/usr/bin/env bash
source "$HOME/.claude/hooks/validate-path.sh"
hook_register "my-hook-name"

# ... hook logic ...

hook_success  # or let EXIT trap handle failure
```

Registration provides:

1. **Timing** - Duration tracked in milliseconds
2. **Status** - Success/failure logged with error context
3. **Aggregation** - `hook_health_summary` returns JSON stats

Health data writes to `~/.claude/hook-health.jsonl`:

```json
{"timestamp": "2026-03-02T14:30:00Z", "hook": "reversal-detector", "status": "success", "duration_ms": 45, "error": null}
```

### Hook Wiring (hooks.jsonc)

Hooks are wired in `~/.claude/settings/common/hooks.jsonc`:

```jsonc
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "~/.claude/hooks/PreToolUse/layering-guard.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "~/.claude/hooks/PostToolUse/impact-extractor.sh"
      }
    ],
    "Stop": [
      // Shell hook for context prep
      {
        "command": "~/.claude/hooks/Stop/tradeoff-context-prep.sh"
      },
      // Agent hook for extraction
      {
        "prompt": "Extract tradeoff documentation...",
        "type": "agent",
        "timeout": 60
      }
    ]
  }
}
```

### Hook Types

| Type | Mechanism | Use Case |
|------|-----------|----------|
| Shell | Bash script | Fast validation, event emission |
| Agent | LLM prompt | Complex extraction, reasoning |

Agent hooks receive context from preceding shell hooks via `systemMessage`.

### Composition Pattern

Hooks follow a standard structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Source shared utilities
source "$HOME/.claude/hooks/validate-path.sh"
hook_register "hook-name"

# 2. Parse input
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# 3. Early exit if not applicable
[[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]] && exit 0

# 4. Perform hook logic
# ...

# 5. Emit event (if applicable)
echo "$INPUT" | safe_emit "event_type" "$PAYLOAD"

# 6. Output result
jq -cn '{ok: true}'  # or systemMessage, or block with ok: false
```

## Consequences

### Positive

- **DRY utilities** - Common operations implemented once
- **Observability** - Health monitoring surfaces slow/failing hooks
- **Organization** - Event-based directories make hooks findable
- **Consistency** - Shared patterns reduce bugs and cognitive load
- **Resilience** - Validation functions return codes instead of exiting
- **Extensibility** - New hooks follow established patterns

### Negative

- **Indirection** - Sourcing shared file adds startup time (~10-20ms)
- **Learning curve** - Contributors must learn the utility API
- **Coupling** - Changes to validate-path.sh affect all hooks
- **Symlink management** - Must keep symlinks in sync with common/

### Neutral

- Health logs grow over time (same rotation concern as event logs)
- EXIT trap catches unexpected failures but may mask some errors
- Agent hooks add latency but provide capabilities shell can't

## Alternatives Considered

### Alternative A: No Shared Utilities

Each hook implements its own validation and emission logic.

**Pros:** No dependencies, simpler to understand in isolation
**Cons:** Massive duplication, inconsistent behavior, hard to maintain
**Why rejected:** Already experiencing duplication pain at current scale

### Alternative B: Single Monolithic Hook

One hook script with a giant switch/case for all events.

**Pros:** Single file to maintain, no sourcing overhead
**Cons:** Massive file, hard to test, can't selectively disable hooks
**Why rejected:** Violates single-responsibility; event-based organization is clearer

### Alternative C: Node.js/Python Hook Runner

Implement hooks in a higher-level language with proper module system.

**Pros:** Better abstractions, easier testing, richer ecosystem
**Cons:** Dependency on runtime, slower startup, different language from settings
**Why rejected:** Shell is fast and universal; can migrate later if complexity warrants

### Alternative D: No Health Monitoring

Skip observability layer to reduce complexity.

**Pros:** Simpler hooks, less overhead
**Cons:** Blind to performance issues, can't diagnose failures
**Why rejected:** Already experienced "hook silently fails" pain; observability is worth the cost

## References

- `home/.claude/hooks/common/validate-path.sh` - Shared utilities implementation
- `home/.claude/hooks/common/dev-os-emit.sh` - Event emission script
- `home/.claude/settings/common/hooks.jsonc` - Hook wiring configuration
- `home/.claude/hooks/README.md` - Comprehensive hook documentation
- `test/hooks/` - BATS test suite for hooks
