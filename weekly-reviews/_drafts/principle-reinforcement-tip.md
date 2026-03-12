---
title: "Quick Tip: Make Your Principles Sticky"
date: 2026-03-10
status: draft
tags: [claude-code, developer-tools, quick-tip, hooks, productivity]
---

# Quick Tip: Make Your Principles Sticky

Here's a pattern I kept noticing: I'd invoke a principle early in a session—"let's make sure we're thinking about separation of concerns here"—and then forget about it completely by the third edit.

The AI would dutifully acknowledge the principle, then move on. Twenty minutes later, we'd violate it. Not maliciously—just forgetfully. The principle got mentioned once and never reinforced.

The fix is embarrassingly simple: **two hooks that remember what you said you cared about**.

## The Problem: Breadth Over Depth

It's easy to cover many ideas shallowly. "Security matters." "Tests should be meaningful." "Domain modeling first." All true. All forgotten within minutes.

Principles that live in documentation don't affect behavior. Principles that get mentioned once don't either. What changes behavior is **repeated reinforcement at decision points**.

## The Solution: Activate, Then Reinforce

Two hooks, ~200 lines total:

### Hook 1: Principle Activator (PostToolUse)

After every tool use, scan the output for principle keywords. When you see "separation of concerns" or "test coverage" or "security", mark that principle as "active" for the session.

```bash
# Detect principle references in tool output
if echo "$TOOL_RESULT" | grep -qiE "security|auth|token|permission|sanitize"; then
  activate_principle "security" ""
fi

if echo "$TOOL_RESULT" | grep -qiE "test.*purpose|meaningful.*test|characterization"; then
  activate_principle "testing-with-purpose" ""
fi
```

Active principles get written to a temp file scoped to the session:

```
/tmp/.claude-active-principles-{session_id}
```

### Hook 2: Principle Reinforcer (PreToolUse)

Before Write/Edit operations, check which active principles are **relevant to the file being changed**. If the file matches, inject a reminder.

```bash
case "$PRINCIPLE_NAME" in
  "security")
    # Only remind when editing auth-related files
    if [[ "$FILE_PATH" =~ auth|session|login|controller ]]; then
      REMINDERS+="- **Security**: Validate input, escape output, check auth\n"
    fi
    ;;
  "testing-with-purpose")
    # Only remind when editing test or source files
    if [[ "$FILE_PATH" =~ _spec\.|_test\. ]]; then
      REMINDERS+="- **Testing**: Is this behavior meaningfully tested?\n"
    fi
    ;;
esac
```

The reminder appears as context before the edit happens:

```
Active principles for this session:
- **Security**: Validate input, escape output, check auth
```

## The Clever Bits

**Rate limiting**: Reminders have a 5-minute cooldown. You don't need to see "remember security!" on every single edit—that would become noise. Once every few minutes is enough to keep it warm.

```bash
if (( NOW - LAST_REMINDER < 300 )); then
  exit 0  # Skip this reminder
fi
```

**Context matching**: Not every principle applies to every file. Security reminders when editing auth code? Useful. Security reminders when editing a README? Noise. The reinforcer only speaks up when the file path matches the principle's domain.

**Telemetry**: Both hooks emit events (`principle_activated`, `principle_reinforced`), so the weekly review can show which principles are actually getting used—and whether they correlate with better outcomes.

## Try It Yourself

The minimal version is just two files:

**`~/.claude/hooks/PostToolUse/principle-activator.sh`**
```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
[[ -z "$SESSION_ID" ]] && exit 0

TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_result // ""')
ACTIVE_FILE="/tmp/.claude-active-principles-${SESSION_ID}"

# Add your own principle patterns
if echo "$TOOL_RESULT" | grep -qiE "security|auth|token|password"; then
  echo "security|$(date +%s)" >> "$ACTIVE_FILE"
fi
# ... more patterns
```

**`~/.claude/hooks/PreToolUse/principle-reinforcer.sh`**
```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

ACTIVE_FILE="/tmp/.claude-active-principles-${SESSION_ID}"
[[ ! -f "$ACTIVE_FILE" ]] && exit 0

# Check for relevant principles and build reminder
# ... (context matching logic)

jq -n --arg ctx "Active principles:\n- Security: check auth" '{
  hookSpecificOutput: {
    additionalContext: $ctx
  }
}'
```

Wire them in your hooks config:

```json
{
  "hooks": {
    "PostToolUse": [
      { "command": "~/.claude/hooks/PostToolUse/principle-activator.sh" }
    ],
    "PreToolUse": [
      { "command": "~/.claude/hooks/PreToolUse/principle-reinforcer.sh" }
    ]
  }
}
```

## Why This Works

The system doesn't make you *follow* principles—it just makes them harder to *forget*. That's often enough.

When I mention "security" early in a session and then start editing an auth controller 20 minutes later, the reminder appears. Not forcing, just prompting: "Hey, you said security mattered. Does this change align?"

That small friction—the moment of reflection before the edit—catches violations that would otherwise slip through.

Principles stop being abstract ideals and become **active participants** in the session.

---

*Full implementation in the [dotfiles](https://github.com/meaganewaller/.dotfiles/tree/main/home/.claude/hooks/common). The activator watches for 9 principle patterns; the reinforcer maps them to file contexts.*
