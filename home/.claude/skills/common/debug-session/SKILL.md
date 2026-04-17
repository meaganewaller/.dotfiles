---
name: debug-session
description: This skill should be used when the user asks to "help me debug", "why isn't this working", "this is broken", "debug this", "find the bug", or when systematically investigating an issue.
argument-hint: error message, symptom description, or file path to investigate
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Bash
---

# Debug Session Skill

## Methodology

### The Debug Loop

```
OBSERVE → HYPOTHESIZE → TEST → CONCLUDE → REPEAT
```

### 1. Observe: Gather Evidence

Before hypothesizing, collect facts:

**Ask these questions:**
- What is the expected behavior?
- What is the actual behavior?
- When did it start happening?
- What changed recently?
- Is it reproducible? Always or intermittently?
- What environment? (dev/staging/prod, browser, OS)

**Collect artifacts:**
- Error messages (exact text)
- Stack traces
- Logs (before, during, after)
- Screenshots/recordings if UI
- Network requests/responses if API

### 2. Hypothesize: Form Theories

Generate hypotheses ranked by:
1. **Likelihood** - What usually causes this?
2. **Testability** - Can we quickly verify/refute?
3. **Recency** - What changed recently?

**Common bug categories:**
- **State bugs**: Wrong initial state, stale state, race condition
- **Data bugs**: Null/undefined, wrong type, malformed input
- **Logic bugs**: Off-by-one, wrong condition, missing case
- **Integration bugs**: API contract mismatch, version incompatibility
- **Environment bugs**: Config diff, missing dependency, permissions

### 3. Test: Verify Hypotheses

For each hypothesis:

```markdown
## Hypothesis: [statement]
**Test**: [how to verify]
**Result**: [what happened]
**Conclusion**: [confirmed/refuted/inconclusive]
```

**Testing strategies:**
- Add logging/breakpoints at key points
- Simplify to minimal reproduction
- Binary search through code/commits
- Compare working vs broken environments
- Test with known good/bad inputs

### 4. Conclude: Document and Fix

Once root cause is found:

```markdown
## Root Cause
[What actually caused the bug]

## Fix
[What change resolves it]

## Verification
[How to confirm the fix works]

## Prevention
[How to prevent similar bugs]
```

## Debug Session Template

```markdown
# Debug Session: [Brief description]

## Problem Statement
**Expected**: [what should happen]
**Actual**: [what happens instead]
**Reproducible**: [always/sometimes/once]

## Evidence Collected
- Error: `[error message]`
- Logs: [relevant log lines]
- Context: [what was happening when it occurred]

## Hypotheses

### H1: [Most likely cause]
- **Likelihood**: High/Medium/Low
- **Test**: [how to verify]
- **Result**: [outcome]

### H2: [Second possibility]
- **Likelihood**: High/Medium/Low
- **Test**: [how to verify]
- **Result**: [outcome]

## Root Cause
[Identified cause after testing]

## Resolution
[Fix applied]

## Lessons Learned
[What to do differently next time]
```

## Debugging Techniques

### Binary Search
If you don't know where the bug is:
1. Find a known working state (commit, version, input)
2. Find the broken state
3. Test the midpoint
4. Repeat until isolated

### Rubber Duck
Explain the problem out loud (or in writing):
- What are you trying to do?
- What have you tried?
- What do you expect at each step?
- What actually happens at each step?

### Minimal Reproduction
Reduce to the smallest case that reproduces:
- Remove unrelated code
- Simplify inputs
- Isolate the system under test

### Printf Debugging
Strategic logging at boundaries:
- Function entry/exit
- Before/after state changes
- API request/response
- Decision points (if/else branches taken)

### Diff Analysis
Compare working vs broken:
- git diff between commits
- Config differences
- Environment variable differences
- Dependency version differences

## Anti-patterns

1. **Shotgun debugging**: Random changes hoping something works
2. **Premature fixing**: Changing code before understanding the bug
3. **Tunnel vision**: Fixating on one hypothesis without testing others
4. **Ignoring evidence**: Dismissing logs/errors that don't fit your theory
5. **Not documenting**: Forgetting the fix and re-debugging later

## When to Escalate

Consider getting help when:
- You've spent 30+ minutes without progress
- The bug is in unfamiliar code/system
- You've ruled out your hypotheses
- The bug is intermittent and hard to reproduce
- The fix might have broad impact

## Example Session

```markdown
# Debug Session: API returns 500 on user update

## Problem Statement
**Expected**: PUT /users/:id returns 200 with updated user
**Actual**: Returns 500 Internal Server Error
**Reproducible**: Always for user ID 12345, works for others

## Evidence Collected
- Error: `NoMethodError: undefined method 'downcase' for nil:NilClass`
- Stack trace points to `app/models/user.rb:45`
- User 12345 has `email: null` in database

## Hypotheses

### H1: Null email field causing downcase call to fail
- **Likelihood**: High (error message matches)
- **Test**: Check if email is null; try with non-null email
- **Result**: Confirmed - email is null, and `email.downcase` at line 45

## Root Cause
The `normalize_email` callback calls `email.downcase` without null check.
User 12345 was created via admin import with null email.

## Resolution
```ruby
def normalize_email
  self.email = email&.downcase
end
```

## Lessons Learned
- Add null checks for optional fields in callbacks
- Add validation to prevent null emails if required
- Admin import should validate data
```
