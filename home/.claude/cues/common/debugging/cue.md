---
pattern: \bbug\b|debug|broken|not.?working|error|exception|crash|fail|issue|problem|wrong|unexpected|investigate|troubleshoot|fix
commands: gdb|lldb|pry|byebug|debugger|binding\.pry|console\.log|print|puts
scope: agent, subagent
description: Systematic debugging approach
vocabulary: bug error exception stack trace breakpoint hypothesis root cause reproduction
provenance:
  policy:
    - uri: home/.claude/governance/policies/incident-response.md
      type: governance-doc
  controls:
    - id: DEBUG-001
      name: Systematic Investigation
      justifications:
        - Random changes waste time
        - Hypothesize-test loop finds bugs faster
    - id: DEBUG-002
      name: Root Cause Analysis
      justifications:
        - Fixing symptoms leads to recurring bugs
        - Understanding cause prevents future issues
---

# Debugging Approach

## The Debug Loop

```
OBSERVE → HYPOTHESIZE → TEST → REPEAT
```

**Don't skip steps.** Resist the urge to immediately change code.

## Step 1: Observe

Gather facts before forming theories:

- **What is the expected behavior?**
- **What is the actual behavior?**
- **What's the exact error message?**
- **Is it reproducible?** (Always/sometimes/once)
- **What changed recently?**

## Step 2: Hypothesize

Form theories ranked by:
1. Likelihood (what usually causes this?)
2. Testability (can we quickly verify?)
3. Recency (what changed?)

**Common bug categories:**
- State: wrong initial value, stale cache, race condition
- Data: null/undefined, wrong type, malformed input
- Logic: off-by-one, wrong condition, missing case
- Integration: API mismatch, version conflict
- Environment: config diff, missing dependency

## Step 3: Test

For each hypothesis:
- State what you expect to observe
- Make ONE change or add ONE log
- Check if result matches expectation
- Conclude: confirmed / refuted / inconclusive

## Debugging Techniques

### Binary Search
Don't know where the bug is?
1. Find last known working state
2. Find broken state
3. Test midpoint
4. Repeat

### Minimal Reproduction
- Remove unrelated code
- Simplify inputs
- Isolate the system

### Printf Debugging
Add logs at:
- Function entry/exit
- Before/after state changes
- Decision branches

### Rubber Duck
Explain the problem out loud:
- What are you trying to do?
- What have you tried?
- What happens at each step?

## Anti-patterns

- **Shotgun debugging**: Random changes hoping to fix it
- **Premature fixing**: Changing code before understanding the bug
- **Ignoring evidence**: Dismissing logs that don't fit your theory
- **Tunnel vision**: Only testing one hypothesis

## When to Ask for Help

- 30+ minutes without progress
- Unfamiliar codebase
- Intermittent/hard to reproduce
- High-risk fix

## Quick Reference

```bash
# Git: What changed?
git diff HEAD~5
git log --oneline -10

# Logs: What happened?
tail -f log/development.log
grep -i error log/*.log

# Processes: What's running?
ps aux | grep [process]
lsof -i :3000
```
