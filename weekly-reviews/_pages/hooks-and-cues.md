---
layout: page
title: Hooks & Cues
permalink: /hooks-and-cues/
updated_at: 2026-03-10
---

# Hooks & Cues

Two systems that work together to provide engineering telemetry and context-aware guidance.

## Overview

| System | Purpose | When it runs |
|--------|---------|--------------|
| **Hooks** | Observe and react to events | Automatically on Claude Code events |
| **Cues** | Inject contextual guidance | When triggers match prompts/commands/files |

## Hooks: Event-Driven Telemetry

Hooks are shell scripts that run in response to Claude Code events.

### Hook Events

| Event | When | Common Uses |
|-------|------|-------------|
| `SessionStart` | Session begins/resumes | Context injection, marker clearing, health reporting |
| `UserPromptSubmit` | User sends prompt | Cue matching, duration monitoring, state triggers |
| `PreToolUse` | Before tool executes | Validation, cue injection, guards, principle reinforcement |
| `PostToolUse` | After tool succeeds | Impact logging, pattern detection, principle activation |
| `PostToolUseFailure` | After tool fails | Friction classification |
| `PreCompact` | Before context compaction | Session health capture, compaction tracking |
| `Stop` | Session ending | Enforcement gates, tradeoff capture |
| `SessionEnd` | Session terminates | Completion metrics, learning suggestions |
| `SubagentStart` | Subagent spawned | Subagent-specific cue injection |
| `TaskCompleted` | Task marked complete | Completion criteria validation |
| `WorktreeCreate` | Git worktree created | Worktree tracking |
| `WorktreeRemove` | Git worktree removed | Worktree cleanup tracking |

### Example: Impact Extractor

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared utilities (required for hook_register)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "impact-extractor"

# Read event payload
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -n "$FILE_PATH" ]]; then
  # Emit structured event
  echo "$INPUT" | "$DEV_OS_EMIT" "tool_write" "{\"files\": [\"$FILE_PATH\"]}"
fi

# Exit 0 = success logged automatically via trap
```

### Hook Registration Pattern

All hooks should use `hook_register` for observability:

```bash
source "$HOME/.claude/hooks/validate-path.sh"
hook_register "my-hook-name"  # Called at start

# Hook logic...

# On success: exit 0 (trap logs automatically)
# On failure: hook_failure "error message"
```

This enables the hook health monitoring system (see [Testing](#testing)).

### Session & Principle Hooks

These hooks implement [ADR-0006](https://github.com/meaganewaller/.dotfiles/blob/main/home/.claude/docs/architecture/0006-skill-vs-cue-design.md) session duration correlation:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-duration-monitor` | UserPromptSubmit | Track duration, classify archetype, provide guidance |
| `principle-activator` | PostToolUse | Detect principle mentions, mark as "active" |
| `principle-reinforcer` | PreToolUse | Re-surface active principles before Write/Edit |
| `pre-compact-snapshot` | PreCompact | Capture session health metrics |

#### Session Duration Monitor

```bash
# Classifies session into archetypes
if (( DURATION_MINUTES >= 120 )); then
  ARCHETYPE="marathon"
  # Suggests break/commit checkpoint
elif (( DURATION_MINUTES >= 30 )); then
  ARCHETYPE="flow"
  # Suggests task list
fi
```

#### Principle Activation Flow

```
1. PostToolUse: Output mentions "model-first"
   → principle-activator marks "model-first" as active

2. PreToolUse (Write): Editing models/user.rb
   → principle-reinforcer checks active principles
   → "model-first" is relevant to models/
   → Injects reminder: "Did you sketch the shape?"
```

### Hook Output

Different events expect different output formats:

| Event | Output Format | Effect |
|-------|---------------|--------|
| PreToolUse | `{"permissionDecision": "allow"}` | Allow tool |
| PreToolUse | `{"ok": false, "error": "..."}` | Block with error |
| PostToolUse | `{"hookSpecificOutput": {"additionalContext": "..."}}` | Inject into context |
| Stop | `{"ok": false, "reason": "..."}` | Block session end |
| Stop | `{"ok": true}` | Allow session end |

### Hook Types

Hooks can be configured as different types:

| Type | Description | Use Case |
|------|-------------|----------|
| `command` | Shell script execution | Most hooks |
| `agent` | Claude subagent with prompt | Complex reasoning (e.g., tradeoff extraction) |
| `async` | Non-blocking execution | Test runners, notifications |

**Agent hook example:**
```json
{
  "type": "agent",
  "prompt": "Analyze this change and extract tradeoffs...",
  "timeout": 60
}
```

**Async hook example:**
```json
{
  "type": "command",
  "command": "~/.claude/hooks/PostToolUse/async-test-runner.sh",
  "async": true
}
```

### Blocking vs Warning

Hooks can either **warn** (inject context) or **block** (prevent action):

```bash
# Warning - inject guidance but allow action
jq -n '{hookSpecificOutput: {additionalContext: "Consider X before proceeding"}}'

# Blocking - prevent action entirely
jq -n '{ok: false, error: "Action blocked because Y"}'
```

**When to block:**
- Action will definitely fail (e.g., reading oversized file)
- Action violates hard constraints (e.g., force-push to main)

**When to warn:**
- Guidance is helpful but action may be valid
- User should make final decision

Example: The `large-file-guard` **blocks** session log reads (they always fail) but **warns** about other large files.

## Cues: Context-Aware Guidance

Cues inject guidance when triggers match. They're "compiled policy"—governance documents compressed into agent directives.

### Cue Format

```yaml
---
# Trigger matching (regex)
pattern: commit|push|amend           # Match user prompts
commands: git\s+(commit|push)        # Match bash commands
files: \.env$|\.env\.local$          # Match file paths

# Scope control
scope: agent                         # agent | subagent | agent, subagent

# Semantic matching (fallback)
description: Git commit workflow and version control
vocabulary: commit push amend rebase merge

# Governance traceability (optional but recommended)
provenance:
  policy:
    - uri: home/.claude/governance/policies/git-workflow.md
      type: governance-doc
  controls:
    - id: GIT-001
      name: Conventional Commits
      justifications:
        - Consistent commit messages enable automated changelogs
---

# Commit Cue

- Use conventional commit format (feat:, fix:, refactor:)
- Sign commits with GPG
- Keep commits atomic and focused
```

### Provenance Block

The `provenance:` block links cues to governance policies for traceability:

| Field | Purpose |
|-------|---------|
| `policy.uri` | Path to governance document |
| `policy.type` | Document type (governance-doc, adr, etc.) |
| `controls.id` | Control identifier for auditing |
| `controls.name` | Human-readable control name |
| `controls.justifications` | Why this control exists |

This enables "compiled policy"—governance documents compressed into agent directives with full traceability.

### Matching Priority

1. **Regex match** - `pattern:`, `commands:`, or `files:` fields
2. **Vocabulary match** - Any word in `vocabulary:` appears in query
3. **Semantic match** - Gzip NCD similarity to `description:`

### Example Triggers

**Prompt trigger:**
```yaml
pattern: commit|push|amend
```
User types "commit my changes" → cue fires

**Command trigger:**
```yaml
commands: git\s+(commit|push|rebase)
```
Claude runs `git commit -m "..."` → cue fires

**File trigger:**
```yaml
files: \.env$|\.env\.local$
```
Claude edits `.env.local` → cue fires

### Scope Filtering

| Scope | Fires For | Use When |
|-------|-----------|----------|
| `agent` | Main agent only | Default; most cues |
| `subagent` | Spawned subagents only | Subagent-specific guidance |
| `agent, subagent` | Both contexts | Universal guidance |

### Once-Per-Session Gating

Each cue fires at most once per session to avoid repetition:

{% mermaid %}
flowchart LR
    A[First 'commit' prompt] --> B[cue fires]
    C[Second 'commit' prompt] --> D[cue skipped<br/>marker exists]
    E[New session starts] --> F[markers cleared]
{% endmermaid %}

## How They Work Together

{% mermaid %}
flowchart TD
    subgraph lifecycle["Session Lifecycle"]
        A[SessionStart] --> A1[Clear cue markers]
        A --> A2[Inject context]
        A --> A3[Escalate friction]

        A --> B[UserPromptSubmit]
        B --> B1[Match cues]
        B1 --> B2[Inject matching cue content]

        B --> C[PreToolUse]
        C --> C1[Match command cues]
        C --> C2[Match file cues]
        C1 & C2 --> C3[Inject matching cue content]

        C --> D[PostToolUse]
        D --> D1[Extract impact]
        D --> D2[Detect patterns]
        D --> D3[Check for reversal]
        D1 --> D4[(dev-os-events.jsonl)]

        D --> E[Stop]
        E --> E1{Tests passing?}
        E1 -->|No| E2[Block]
        E1 -->|Yes| E3{Tradeoffs documented?}
        E3 -->|No| E4[Prompt]
        E3 -->|Yes| E5[Allow stop]
    end
{% endmermaid %}

## Cue Engagement Tracking

When a cue fires, an event is logged:

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

The weekly review aggregates this to show:
- Which cues are actively providing guidance
- Trigger patterns (prompt vs bash vs file)
- Dormant cues that may need better triggers

## Creating Hooks

### Basic Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read event payload from stdin
INPUT=$(cat)

# Extract fields
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Your logic
if [[ -n "$FILE_PATH" ]]; then
  # Do something
fi

# Optional output
echo '{"hookSpecificOutput": {"context": "Your message here"}}'
```

### Configuration

Add to `~/.claude/settings/common/hooks.jsonc` (or `~/.claude/settings.json`):

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$HOME\"/.claude/hooks/PostToolUse/my-hook.sh"
          },
          {
            "type": "command",
            "command": "\"$HOME\"/.claude/hooks/PostToolUse/async-task.sh",
            "async": true
          }
        ]
      },
      {
        "matcher": "*",  // All tools
        "hooks": [
          {
            "type": "command",
            "command": "\"$HOME\"/.claude/hooks/PostToolUse/universal-hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Key points:**
- Use `hooks:` array for multiple hooks per matcher
- Quote `$HOME` as `"$HOME"` for shell expansion
- Use `async: true` for non-blocking hooks
- Matcher `*` matches all tools

## Creating Cues

### Cue Locations

Cues are loaded from two locations:

| Location | Scope | Use Case |
|----------|-------|----------|
| `~/.claude/cues/` | Global | Personal conventions across all projects |
| `PROJECT/.claude/cues/` | Project | Project-specific guidance |

Project cues override global cues with the same name.

### Basic Cue

```yaml
---
pattern: docker|container
scope: agent
description: Docker and containerization workflows
vocabulary: docker container dockerfile compose kubernetes
---

# Docker Cue

- Use multi-stage builds to reduce image size
- Never store secrets in Dockerfiles
- Pin base image versions for reproducibility
```

### Cue with Macro

Macros add dynamic content:

```yaml
---
files: Gemfile$
scope: agent
macro: prepend
---

# Ruby Dependencies

- Run `bundle install` after Gemfile changes
```

```bash
# cues/ruby-deps/macro.sh
#!/usr/bin/env bash
if [[ -f "Gemfile.lock" ]]; then
  ruby_version=$(grep -A1 "RUBY VERSION" Gemfile.lock | tail -1)
  echo "**Ruby version**: $ruby_version"
fi
```

## Testing

### Test Hook

```bash
echo '{"tool_name": "Write", "tool_input": {"file_path": "test.rb"}}' | \
  ~/.claude/hooks/PostToolUse/my-hook.sh
```

### Test Cue Matching

```bash
~/.claude/hooks/match-cues.sh prompt "commit my changes"
~/.claude/hooks/match-cues.sh command "git push origin main"
~/.claude/hooks/match-cues.sh file ".env.local"
```

### Preview Cue Content

```bash
~/.claude/hooks/show-cue.sh commit  # Show cue body without frontmatter
```

### Hook Health CLI

The `hook-health.sh` CLI provides observability into hook execution:

```bash
# Summary reports
hook-health.sh              # 24-hour summary
hook-health.sh 168          # 7-day summary (168 hours)

# Real-time monitoring
hook-health.sh --recent     # Last 10 executions
hook-health.sh --tail       # Follow log in real-time
hook-health.sh --failures   # Show only failures
```

**Example output:**
```
=== Hook Health Report (24h) ===

✓ All hooks healthy - 245 successful executions

Per-Hook Breakdown:
  ✓ impact-extractor: 89 ok (12ms avg)
  ✓ skill-gap-detector: 45 ok (8ms avg)
  ✓ cue-injector-prompt: 111 ok (15ms avg)
```

### Health Log Location

Hook health data is logged to `~/.claude/hook-health.jsonl`:

```json
{
  "timestamp": "2026-03-10T15:30:00Z",
  "hook": "impact-extractor",
  "status": "success",
  "duration_ms": 12,
  "error": null
}
```

## Shared Utilities

The `validate-path.sh` script provides common utilities for hooks:

### Path Constants

```bash
source "$HOME/.claude/hooks/validate-path.sh"

$CLAUDE_HOME              # ~/.claude
$CLAUDE_EVENTS_LOG        # ~/.claude/dev-os-events.jsonl
$CLAUDE_FRICTION_LOG      # ~/.claude/skill-friction-log.jsonl
$CLAUDE_IMPACT_LOG        # ~/.claude/impact-log.jsonl
$CLAUDE_HOOK_HEALTH_LOG   # ~/.claude/hook-health.jsonl
$DEV_OS_EMIT              # ~/.claude/hooks/dev-os-emit.sh
```

### Validation Functions

```bash
# Check existence (returns 0/1, never exits)
validate_file_exists "/path/to/file"
validate_file_readable "/path/to/file"
validate_file_writable "/path/to/file"
validate_dir_exists "/path/to/dir"

# Create if needed
ensure_dir_exists "/path/to/dir"
ensure_file_exists "/path/to/file"

# Size guards
guard_log_size "$LOG_FILE" 50  # Warn if >50MB
```

### Hook Health Functions

```bash
hook_register "my-hook"     # Start timing, set up trap
hook_success                # Explicit success (optional)
hook_failure "error msg"    # Log failure with message
hook_health_summary 24      # Get JSON summary for last 24h
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_HOME` | `~/.claude` | Base directory |
| `CLAUDE_PROJECT_DIR` | Current project | Project context |
| `CUE_SCOPE_FILTER` | `agent` | Cue scope filtering |
| `CUE_SEMANTIC` | `1` | Enable semantic matching |
| `NCD_THRESHOLD` | `0.58` | Semantic similarity threshold |

---

Previous: [Review Pipeline](/review-pipeline/) | Next: [Event Schema](/event-schema/)
