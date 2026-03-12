---
layout: glossary-term
term: Hook
short: Shell script triggered by Claude Code events
category: telemetry
related:
  - event
  - cue
  - telemetry
aliases:
  - hooks
---

A shell script that runs in response to Claude Code events to observe activity and emit structured telemetry.

## Hook Events

| Event | When | Use |
|-------|------|-----|
| `SessionStart` | Session begins | Context injection, marker clearing |
| `UserPromptSubmit` | User sends prompt | Cue matching, duration monitoring |
| `PreToolUse` | Before tool runs | Validation, cue injection, principle reinforcement |
| `PostToolUse` | After tool succeeds | Impact logging, principle activation |
| `PostToolUseFailure` | After tool fails | Friction classification |
| `PreCompact` | Before context compaction | Session health capture |
| `Stop` | Session ending | Enforcement gates |

## Hook Types

- **Observation hooks** - Log what happens (impact-extractor, skill-gap-detector, principle-activator)
- **Enforcement hooks** - Block actions when conditions aren't met (test-blocker, large-file-guard)
- **Injection hooks** - Add context to sessions (cue-injector, friction-escalator, principle-reinforcer)
- **Session hooks** - Track session health (session-duration-monitor, pre-compact-snapshot)

## Example

```bash
#!/usr/bin/env bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path')
echo "$INPUT" | dev-os-emit.sh "tool_write" "{\"file\": \"$FILE\"}"
```
