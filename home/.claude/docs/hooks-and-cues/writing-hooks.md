# Writing Hooks

> **Audience**: Contributors extending the hook system

This guide covers how to create new hooks for the Dev OS telemetry system.

## Quick Start

```bash
# 1. Create script in appropriate event directory
vim hooks/common/PostToolUse/my-hook.sh

# 2. Make executable
chmod +x hooks/common/PostToolUse/my-hook.sh

# 3. Add to settings
vim settings/common/hooks.jsonc

# 4. Refresh configuration
mise run claude:refresh
```

## Hook Events

| Event | When | Common Uses |
|-------|------|-------------|
| `SessionStart` | Session begins/resumes | Context injection, marker clearing |
| `UserPromptSubmit` | User sends prompt | Cue matching, state triggers |
| `PreToolUse` | Before tool executes | Validation, cue injection |
| `PostToolUse` | After tool succeeds | Impact logging, pattern detection |
| `PostToolUseFailure` | After tool fails | Friction classification |
| `SubagentStart` | Subagent spawns | Cue injection for subagents |
| `Stop` | Session ending | Enforcement gates |
| `TaskCompleted` | Task marked done | Validation gates |
| `PreCompact` | Before context compaction | Snapshot preservation |
| `SessionEnd` | Session terminates | Learning suggestions |

## Hook Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring (optional but recommended)
hook_register "my-hook-name"

# Read event payload from stdin
INPUT=$(cat)

# Extract fields using jq
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Your logic here
if [[ -n "$FILE_PATH" ]]; then
  # Do something
  :
fi

# Output (optional, depends on event type)
# echo '{"hookSpecificOutput": {"context": "injected text"}}'
```

## Input/Output Conventions

### Input (stdin)

Hooks receive JSON on stdin. Structure varies by event:

```json
// PostToolUse example
{
  "session_id": "abc123",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.rb",
    "content": "..."
  }
}
```

### Output (stdout)

| Event | Output Format | Effect |
|-------|---------------|--------|
| PreToolUse | `{"permissionDecision": "allow"}` | Allow/block tool |
| PostToolUse | `{"hookSpecificOutput": {"context": "..."}}` | Inject into context |
| Stop | `{"ok": false, "reason": "..."}` | Block session end |
| Most events | (none required) | Side effects only |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (may surface in UI) |
| 2 | Block action (TaskCompleted, Stop) |

## Settings Configuration

Add hooks to `settings/common/hooks.jsonc`:

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",  // Optional: limit to specific tools
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/PostToolUse/my-hook.sh"
      }
    ]
  }
}
```

### Matcher Patterns

- Regex matching tool names: `"Write|Edit"`, `"Bash"`
- For SessionStart: `"startup|resume"`
- Omit for all triggers

### Async Execution

```jsonc
{
  "command": "...",
  "async": true  // Don't block on completion
}
```

## Helper Functions

Source `validate-path.sh` for utilities:

```bash
source "$SCRIPT_DIR/validate-path.sh"

# Path constants
echo "$CLAUDE_HOME"           # ~/.claude
echo "$CLAUDE_EVENTS_LOG"     # ~/.claude/dev-os-events.jsonl
echo "$CLAUDE_FRICTION_LOG"   # ~/.claude/skill-friction-log.jsonl

# Validation
validate_file_exists "$path"
validate_dir_exists "$dir"

# Safe I/O
safe_append "$file" "$content"
safe_emit "event_type" '{"key": "value"}'

# Resource guards
guard_file_size "$file" 1000000  # Max 1MB
guard_log_size "$log" 10000      # Max 10K lines
```

## Emitting Events

Use `dev-os-emit.sh` for structured events:

```bash
echo "$INPUT" | "$SCRIPT_DIR/dev-os-emit.sh" "my_event" '{"key": "value"}'
```

Event types: `tool_write`, `tool_failure`, `large_change`, `reversal`, `test_run`, `task_completed`

## Health Monitoring

Register hooks for observability:

```bash
source "$SCRIPT_DIR/validate-path.sh"
hook_register "my-hook-name"

# ... hook logic ...

# Exit trap automatically logs success/failure
```

Check health with:

```bash
~/.claude/hooks/hook-health.sh           # 24h summary
~/.claude/hooks/hook-health.sh --recent  # Last 10 runs
~/.claude/hooks/hook-health.sh --failures
```

## Testing

```bash
# Test with sample input
echo '{"tool_name": "Write", "tool_input": {"file_path": "test.rb"}}' | \
  ./hooks/common/PostToolUse/my-hook.sh

# Check output
echo $?  # Exit code

# Verify events logged
tail -1 ~/.claude/dev-os-events.jsonl | jq .
```

## Examples

### Simple Logger

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -n "$FILE" ]]; then
  echo "$(date -Iseconds) Wrote: $FILE" >> ~/.claude/write-log.txt
fi
```

### Enforcement Gate

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check condition
if [[ -f ~/.claude/block-marker ]]; then
  echo '{"ok": false, "reason": "Blocked by marker file"}'
else
  echo '{"ok": true}'
fi
```

### Context Injector

```bash
#!/usr/bin/env bash
set -euo pipefail

CONTEXT="Remember to run tests after editing."
echo "{\"hookSpecificOutput\": {\"context\": \"$CONTEXT\"}}"
```

## Related Documentation

- [Overview](overview.md) - How hooks and cues work together
- [hooks/README.md](../../hooks/README.md) - Detailed hook reference
