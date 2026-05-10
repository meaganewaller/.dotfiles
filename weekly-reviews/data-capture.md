---
layout: page
title: Data Capture
permalink: /data-capture/
updated_at: 2026-03-10
---

# Data Capture

How development activity becomes structured events.

## The Hook System

Claude Code supports hooks—shell scripts that run in response to events. Dev OS uses hooks to observe activity and emit structured telemetry.

### Event Flow Overview

{% mermaid %}
flowchart LR
    A[Session Lifecycle] --> B[Tool Execution] --> C[Context Management] --> D[Session End]
    A --> E[(events.jsonl)]
    B --> E
    C --> E
    D --> E
{% endmermaid %}

The hook system spans four phases:

| Phase | Events | Purpose |
|-------|--------|---------|
| Session Lifecycle | SessionStart, UserPromptSubmit | Initialize context, track duration |
| Tool Execution | PreToolUse, PostToolUse, PostToolUseFailure | Guard, observe, classify |
| Context Management | PreCompact, SubagentStart, TaskCompleted | Health, delegation, tasks |
| Session End | Stop, SessionEnd, Worktree* | Block, evaluate, cleanup |

---

### Session Lifecycle Hooks

{% mermaid %}
flowchart TD
    subgraph SessionStart
        A1[session-context-injector] --> A2[Inject recent activity]
        A3[friction-escalator] --> A4[Warn on repeated errors]
        A5[hook-health-reporter] --> A6[Report hook status]
        A7[session-start-tracker] --> A8[Log session start]
    end
{% endmermaid %}

{% mermaid %}
flowchart TD
    subgraph UserPromptSubmit
        B1[cue-injector-prompt] --> B2[Match cues to prompt]
        B3[session-duration-monitor] --> B4[Track archetype]
        B5[idea-classifier] --> B6[Detect domain modeling]
        B7[state-triggers] --> B8[Trigger state transitions]
    end
{% endmermaid %}

---

### Tool Execution Hooks

{% mermaid %}
flowchart TD
    subgraph PreToolUse
        C1[cue-injector-bash] --> C2[Cues for commands]
        C3[cue-injector-file] --> C4[Cues for file paths]
        C5[principle-reinforcer] --> C6[Surface active principles]
        C7[large-file-guard] --> C8[Block/warn large reads]
        C9[bulk-operation-estimator] --> C10[Estimate batch size]
        C11[git-guard] --> C12[Protect branches]
        C13[layering-guard] --> C14[Enforce architecture]
    end
{% endmermaid %}

{% mermaid %}
flowchart TD
    subgraph PostToolUse
        D1[impact-extractor] --> D2[Log file changes]
        D3[large-diff-escalator] --> D4[Flag >250 lines]
        D5[reversal-detector] --> D6[Detect undos]
        D7[principle-activator] --> D8[Track first mentions]
        D9[loop-detector] --> D10[Detect repeated patterns]
        D11[skill-usage-tracker] --> D12[Track skill invocations]
        D13[tradeoff-capture] --> D14[Capture decisions]
        D15[dependency-change-detector] --> D16[Track dep changes]
    end
{% endmermaid %}

{% mermaid %}
flowchart TD
    subgraph PostToolUseFailure
        E1[skill-gap-detector] --> E2[Classify error domain]
        E2 --> E3[Generate hints]
        E3 --> E4[tool_failure event]
    end
{% endmermaid %}

---

### Context Management Hooks

{% mermaid %}
flowchart TD
    subgraph PreCompact
        F1[pre-compact-snapshot] --> F2[Capture session health]
        F3[context-compact-tracker] --> F4[Track compaction frequency]
    end
    subgraph SubagentStart
        G1[cue-inject-subagent] --> G2[Inject cues for subagent]
    end
    subgraph TaskCompleted
        H1[task-gate] --> H2[Validate completion criteria]
    end
{% endmermaid %}

---

### Session End Hooks

{% mermaid %}
flowchart TD
    subgraph Stop
        I1[hard-stop-test-blocker] --> I2{Tests pass?}
        I2 -->|No| I3[Block stop]
        I2 -->|Yes| I4[tradeoff-context-prep]
        I4 --> I5[leverage-evaluator]
        I5 --> I6[response-topics-writer]
    end
{% endmermaid %}

{% mermaid %}
flowchart TD
    subgraph SessionEnd
        J1[session-end-tracker] --> J2[Log completion metrics]
        J3[learning-suggestion-generator] --> J4[Generate study recs]
    end
    subgraph WorktreeEvents
        K1[worktree-create-log] --> K2[Log worktree creation]
        K3[worktree-remove-log] --> K4[Log worktree removal]
    end
{% endmermaid %}

## Hook Categories

### Observation Hooks

Run after tool execution to log what happened.

| Hook | Trigger | What it captures |
|------|---------|------------------|
| `impact-extractor.sh` | PostToolUse | File writes with metadata |
| `skill-gap-detector.sh` | PostToolUseFailure | Errors classified by domain |
| `reversal-detector.sh` | PostToolUse | When recent work is undone |
| `large-diff-escalator.sh` | PostToolUse | Changes > 250 lines |
| `loop-detector.sh` | PostToolUse | Repeated tool patterns |
| `skill-usage-tracker.sh` | PostToolUse | Which skills are invoked |
| `tradeoff-capture.sh` | PostToolUse | Tradeoff documentation |
| `dependency-change-detector.sh` | PostToolUse | Package/gem changes |

### Enforcement Hooks

Block actions when conditions aren't met.

| Hook | Trigger | What it enforces |
|------|---------|------------------|
| `hard-stop-test-blocker.sh` | Stop | Last test must pass |
| `tradeoff-context-prep.sh` | Stop | Large changes need docs |
| `task-gate.sh` | TaskCompleted | Task completion criteria |
| `git-guard.sh` | PreToolUse | Protected branch rules |
| `layering-guard.sh` | PreToolUse | Architectural boundaries |

### Injection Hooks

Add context to the session.

| Hook | Trigger | What it injects |
|------|---------|-----------------|
| `session-context-injector.sh` | SessionStart | Recent impact/friction |
| `friction-escalator.sh` | SessionStart | Repeated error warnings |
| `cue-injector-prompt.sh` | UserPromptSubmit | Cues matching prompt content |
| `cue-injector-bash.sh` | PreToolUse | Cues for bash commands |
| `cue-injector-file.sh` | PreToolUse | Cues for file paths |
| `cue-inject-subagent.sh` | SubagentStart | Cues for subagent context |
| `principle-reinforcer.sh` | PreToolUse | Active principles before writes |
| `state-triggers.sh` | UserPromptSubmit | State machine transitions |

### Session & Principle Hooks

Track session health and principle application.

| Hook | Trigger | What it captures |
|------|---------|------------------|
| `session-duration-monitor.sh` | UserPromptSubmit | Duration, archetype, guidance |
| `pre-compact-snapshot.sh` | PreCompact | Session health metrics |
| `context-compact-tracker.sh` | PreCompact | Compaction frequency |
| `principle-activator.sh` | PostToolUse | First principle invocations |
| `idea-classifier.sh` | UserPromptSubmit | Domain modeling prompts |
| `session-start-tracker.sh` | SessionStart | Session initialization |
| `session-end-tracker.sh` | SessionEnd | Session completion |
| `hook-health-reporter.sh` | SessionStart | Hook system status |

### Session End Hooks

Run when a session terminates.

| Hook | Trigger | What it captures |
|------|---------|------------------|
| `session-end-tracker.sh` | SessionEnd | Session completion metrics |
| `learning-suggestion-generator.sh` | SessionEnd | Study recommendations from friction |

### Stop Hooks

Run when stop is requested, can block or prepare context.

| Hook | Trigger | What it does |
|------|---------|--------------|
| `hard-stop-test-blocker.sh` | Stop | Blocks if last test failed |
| `tradeoff-context-prep.sh` | Stop | Prompts for tradeoff docs |
| `leverage-evaluator.sh` | Stop | Evaluates session leverage |
| `response-topics-writer.sh` | Stop | Captures response topics |

### Worktree Hooks

Track git worktree operations.

| Hook | Trigger | What it captures |
|------|---------|------------------|
| `worktree-create-log.sh` | WorktreeCreate | Worktree creation events |
| `worktree-remove-log.sh` | WorktreeRemove | Worktree removal events |

### Guard Hooks

Block or warn about risky operations.

| Hook | Trigger | What it guards |
|------|---------|----------------|
| `large-file-guard.sh` | PreToolUse | Session logs (blocks), large files (warns) |
| `bulk-operation-estimator.sh` | PreToolUse | Batch operations (estimates size) |
| `git-guard.sh` | PreToolUse | Protected branches (blocks commits to main) |
| `layering-guard.sh` | PreToolUse | Architectural layers (warns on violations) |

## Event Creation Flow

### Code Changes

When you edit a file:

{% mermaid %}
flowchart TD
    A[Edit service.rb] --> B[impact-extractor.sh]
    B --> C[Extracts file path]
    B --> D[Classifies change type]
    B --> E[Assesses risk level]
    C & D & E --> F[tool_write event]
{% endmermaid %}

**Example event:**
```json
{
  "event_type": "tool_write",
  "payload": {
    "files": ["service.rb"],
    "change_type": "refactor",
    "risk_level": "low"
  }
}
```

### Auto-Classification

The system guesses what kind of work you're doing:

{% mermaid %}
flowchart TD
    A[File path] --> B{Contains test/spec?}
    B -->|Yes| C[change_type: test]
    B -->|No| D{Contains config?}
    D -->|Yes| E[change_type: infra]
    D -->|No| F[change_type: refactor]
{% endmermaid %}

### Risk Assessment

{% mermaid %}
flowchart TD
    A[Diff content] --> B{Has class/module/def?}
    B -->|Yes| C[risk: medium<br/>change_type: architecture]
    B -->|No| D[risk: low]
{% endmermaid %}

## Error Classification

When a tool fails, `skill-gap-detector.sh` classifies it:

{% mermaid %}
flowchart TD
    A[Tool fails] --> B[skill-gap-detector.sh]
    B --> C[Match error patterns]
    B --> D[Assign domain]
    B --> E[Assign subdomain]
    B --> F[Generate hints]
    C & D & E & F --> G[tool_failure event]
{% endmermaid %}

**Example event:**
```json
{
  "event_type": "tool_failure",
  "payload": {
    "domain": "state",
    "subdomain": "file-not-found",
    "hints": ["Check path exists"]
  }
}
```

See [Friction Taxonomy](/friction-taxonomy/) for the complete classification system.

## Large Change Detection

Changes exceeding 250 lines trigger special handling:

{% mermaid %}
flowchart TD
    A[Edit file] --> B[git diff --shortstat]
    B --> C{lines > 250?}
    C -->|No| D[no action]
    C -->|Yes| E[large_change event]
    E --> F[System prompts for tradeoff documentation]
    F --> G[decision_tradeoff event]
{% endmermaid %}

## Test Tracking

Test runs are captured automatically:

{% mermaid %}
flowchart TD
    A[Edit .rb/.ts/.js] --> B[async-test-runner.sh]
    B --> C[Run tests in background]
    C --> D[test_run event]
{% endmermaid %}

**Example event:**
```json
{
  "event_type": "test_run",
  "payload": {
    "passed": true,
    "tests": ["spec/..."]
  }
}
```

## Session Duration Tracking

Sessions are monitored for duration and classified into archetypes:

{% mermaid %}
flowchart TD
    A[User submits prompt] --> B[session-duration-monitor.sh]
    B --> C{Duration?}
    C -->|<30 min| D[Sprint archetype]
    C -->|30-120 min| E[Flow archetype]
    C -->|>120 min| F[Marathon archetype]
    D & E & F --> G[session_duration event]
    F --> H[Suggest break/commit]
{% endmermaid %}

**Example event:**
```json
{
  "event_type": "session_duration",
  "payload": {
    "duration_minutes": 145,
    "archetype": "marathon",
    "has_task_list": true
  }
}
```

## Principle Activation

Principles are tracked through activation (first mention) and reinforcement (re-surfacing):

{% mermaid %}
flowchart TD
    A[Output mentions 'model-first'] --> B[principle-activator.sh]
    B --> C[Mark principle active]
    C --> D[principle_activated event]
    E[Later: Write to models/] --> F[principle-reinforcer.sh]
    F --> G{Active principle relevant?}
    G -->|Yes| H[Inject reminder]
    H --> I[principle_reinforced event]
{% endmermaid %}

**Example activation:**
```json
{
  "event_type": "principle_activated",
  "payload": {
    "principle": "model-first",
    "activation": "first_invocation"
  }
}
```

## Domain Modeling Detection

Prompts indicating upfront design work are tracked:

{% mermaid %}
flowchart TD
    A[User asks 'what entities do we need?'] --> B[idea-classifier.sh]
    B --> C[Pattern match: domain modeling]
    C --> D[domain_modeling event]
{% endmermaid %}

Tracked to correlate modeling frequency with reversal rates.

## Session Lifecycle

### Session Start

{% mermaid %}
flowchart TD
    A[Claude starts] --> B[session-context-injector.sh]
    A --> C[friction-escalator.sh]
    A --> D[hook-health-reporter.sh]
    A --> E[session-start-tracker.sh]
    A --> F[clear-cue-markers.sh]
    B --> G[Inject recent impact/friction]
    C --> H[Warn if repeated errors]
    D --> I[Report hook health]
    E --> J[Log session start]
{% endmermaid %}

### On Each Prompt

{% mermaid %}
flowchart TD
    A[User submits prompt] --> B[cue-injector-prompt.sh]
    A --> C[session-duration-monitor.sh]
    A --> D[idea-classifier.sh]
    A --> E[state-triggers.sh]
    B --> F[Inject matching cues]
    C --> G[Track duration/archetype]
    D --> H[Detect domain modeling]
    E --> I[Trigger state transitions]
{% endmermaid %}

### During Work

{% mermaid %}
flowchart TD
    A[Edit file] --> B[PostToolUse hooks]
    B --> C[impact-extractor.sh]
    B --> D[large-diff-escalator.sh]
    B --> E[reversal-detector.sh]
    B --> F[principle-activator.sh]
    B --> G[loop-detector.sh]
    B --> H[dependency-change-detector.sh]
    C --> I[Log impact]
    D --> J[Flag if large]
    E --> K[Detect undos]
    F --> L[Track principles]
    G --> M[Detect loops]
    H --> N[Track dep changes]
{% endmermaid %}

### Before Compaction

{% mermaid %}
flowchart TD
    A[Context pressure] --> B[pre-compact-snapshot.sh]
    A --> C[context-compact-tracker.sh]
    B --> D[Capture session health]
    C --> E[Track compaction frequency]
    D --> F[session_health event]
{% endmermaid %}

### Session End

{% mermaid %}
flowchart TD
    A[Stop requested] --> B[hard-stop-test-blocker.sh]
    B --> C{Tests passing?}
    C -->|No| D[Block stop]
    C -->|Yes| E[tradeoff-context-prep.sh]
    E --> F{Large changes documented?}
    F -->|No| G[Prompt for tradeoffs]
    F -->|Yes| H[leverage-evaluator.sh]
    H --> I[response-topics-writer.sh]
    I --> J[Allow stop]
{% endmermaid %}

### After Session Ends

{% mermaid %}
flowchart TD
    A[Session terminates] --> B[session-end-tracker.sh]
    A --> C[learning-suggestion-generator.sh]
    B --> D[Log completion metrics]
    C --> E[Generate study recommendations]
{% endmermaid %}

## Storage Layout

All captured data lands in `~/.claude/`:

{% mermaid %}
flowchart TB
    subgraph claude["~/.claude/"]
        A[(dev-os-events.jsonl<br/>All events)]
        B[(impact-log.jsonl<br/>File changes)]
        C[(skill-friction-log.jsonl<br/>Errors)]
        D[idea-vault.md<br/>Captured opinions]
        E[learning-targets/<br/>Study guides]
        F[session-summaries/<br/>Snapshots]
        G[reviews/<br/>Weekly reports]
    end
{% endmermaid %}

## What Gets Captured

| You Do This | Event Created | Shows Up In |
|-------------|---------------|-------------|
| Edit file | tool_write | Writes count |
| Big edit (>250 lines) | large_change | Discipline flags |
| Update deps | dependency_change | Churn tracking |
| Delete lots of code | reversal | Reversal count |
| Tool fails | tool_failure | Friction analysis |
| Run tests | test_run | Test stability |
| Complete task | task_completed | Tasks count |
| Explain tradeoff | decision_tradeoff | Principles invoked |
| Work for 30+ minutes | session_duration | Archetype distribution |
| Hit context limit | session_health | Session health score |
| Mention a principle | principle_activated | Principles invoked |
| Write after principle | principle_reinforced | Reinforcement depth |
| Ask about entities | domain_modeling | Modeling ratio |
| Use a skill | skill_usage | Skill invocation tracking |
| Repeat tool pattern | loop_detected | Loop analysis |
| Start session | session_start | Session metrics |
| End session | session_end | Session completion |
| Create worktree | worktree_created | Worktree tracking |
| Remove worktree | worktree_removed | Worktree tracking |
| Spawn subagent | subagent_start | Delegation patterns |

---

Next: [Friction Taxonomy](/friction-taxonomy/) | [Review Pipeline](/review-pipeline/)
