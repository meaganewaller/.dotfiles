# Hooks and Cues Overview

> **Audience**: Contributors understanding the system, operators debugging issues

This document explains how the hooks and cues systems work together to provide engineering telemetry and context-aware guidance.

## Two Systems, One Goal

| System | Purpose | When it runs |
|--------|---------|--------------|
| **Hooks** | Observe and react to events | Automatically on Claude Code events |
| **Cues** | Inject contextual guidance | When triggers match prompts/commands/files |

## Hooks: Dev OS Telemetry

Hooks observe Claude Code sessions and emit structured events for analysis.

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
│   │ cue inject  │   │ large-diff  │   │                     │          │
│   │             │   │ reversal    │   │                     │          │
│   └─────────────┘   └─────────────┘   └─────────────────────┘          │
│                                                                         │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────────────┐          │
│   │SessionStart │   │    Stop     │   │   SubagentStart     │          │
│   │ ─────────── │   │ ─────────── │   │ ─────────────────── │          │
│   │ friction    │   │ test        │   │ cue inject          │          │
│   │ escalator   │   │ blocker     │   │                     │          │
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
                     └───────────────────────┘
                                   │
                                   ▼
                     ┌───────────────────────┐
                     │   /weekly-review      │
                     │   skill aggregates    │
                     └───────────────────────┘
```

### Event Types

| Event Type | Trigger | Payload |
|------------|---------|---------|
| `tool_write` | File created/edited | files, change_type, risk_level |
| `tool_failure` | Any tool error | domain, subdomain, hints |
| `large_change` | Diff > 250 lines | file_path, line_count |
| `reversal` | Undoing recent work | reverted_file, reason |
| `decision_tradeoff` | Architectural decision | options, tradeoffs |
| `test_run` | Test execution | pass/fail, test names |

### Hook Categories

**Observation hooks** (PostToolUse, PostToolUseFailure):
- `impact-extractor.sh` - Logs file writes with metadata
- `skill-gap-detector.sh` - Classifies errors into friction taxonomy
- `reversal-detector.sh` - Detects when recent work is undone

**Enforcement hooks** (Stop, TaskCompleted):
- `hard-stop-test-blocker.sh` - Blocks stop if last test failed
- `pending-tradeoff-blocker.sh` - Blocks stop if large changes undocumented
- `task-gate.sh` - Validates task completion criteria

**Injection hooks** (SessionStart, PreToolUse, SubagentStart):
- `session-context-injector.sh` - Injects project context
- `cue-injector-*.sh` - Injects matching cues
- `friction-escalator.sh` - Surfaces repeated friction patterns

### Friction Taxonomy

Tool failures are classified for pattern detection:

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

## Cues: Context-Aware Guidance

Cues inject guidance when triggers match. They're "compiled policy" - governance documents compressed into agent directives.

### Trigger Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            Cue Trigger Flow                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   User Prompt ──▶ pattern: regex ──┐                                        │
│   Bash Command ─▶ commands: regex ─┼──▶ match-cues.sh ──▶ show-cue.sh      │
│   File Path ────▶ files: regex ────┘         │                │             │
│                                              │                ▼             │
│                  vocabulary: keywords ───────┼──▶ Semantic   Macro         │
│                  description: text ──────────┘    Match      Execution     │
│                                                     │            │          │
│                                                     └─────┬──────┘          │
│                                                           ▼                 │
│                                              hookSpecificOutput.context     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Matching Priority

1. **Regex match** - `pattern:`, `commands:`, or `files:` fields
2. **Vocabulary match** - Any word in `vocabulary:` appears in query
3. **Semantic match** - Gzip NCD similarity to `description:`

### Scope Filtering

| Scope | Fires For |
|-------|-----------|
| `agent` | Main agent only (default) |
| `subagent` | Spawned subagents only |
| `agent, subagent` | Both contexts |

### Once-Per-Session Gating

Each cue fires at most once per session. Markers in `/tmp/.claude-devos-cue-*` track fired cues. `clear-cue-markers.sh` resets on SessionStart.

### Engagement Tracking

When a cue fires, `show-cue.sh` emits a `cue_fired` event to `dev-os-events.jsonl`:

```json
{
  "event_type": "cue_fired",
  "payload": {
    "cue_id": "commit",
    "trigger_type": "prompt",
    "has_macro": false
  }
}
```

The weekly review aggregates this data to show:
- Which cues are actively providing guidance
- Trigger patterns (prompt vs bash vs file)
- Dormant cues that may need better triggers

## How They Work Together

1. **SessionStart**: Hooks clear markers, inject context, escalate friction
2. **UserPromptSubmit**: Cue injector matches prompt to cues
3. **PreToolUse**: Cue injector matches commands/files; layering guard validates
4. **PostToolUse**: Hooks extract impact, detect patterns, emit events
5. **Stop**: Hooks enforce test passing and tradeoff documentation

## Related Documentation

- [Writing Hooks](writing-hooks.md) - How to create new hooks
- [Writing Cues](writing-cues.md) - How to create new cues
- [Governance](../../governance/README.md) - Policy traceability
- [hooks/README.md](../../hooks/README.md) - Detailed hook reference
