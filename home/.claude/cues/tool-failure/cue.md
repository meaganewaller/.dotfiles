---
pattern: failed|error|exception|not.?found|permission.?denied|timeout|refused
scope: agent, subagent
description: Recovery guidance when tool calls fail
vocabulary: error failed failure exception timeout refused denied retry recovery
provenance:
  policy:
    - uri: home/.claude/governance/policies/efficiency.md
      type: governance-doc
    - uri: home/.claude/governance/policies/reliability.md
      type: governance-doc
  controls:
    - id: ENG-EFF-001
      name: Two-Attempt Recovery Limit
      justifications:
        - After two attempts with different strategies, escalate
        - Prevents infinite retry loops
    - id: ENG-EFF-002
      name: Root Cause Diagnosis
      justifications:
        - Understand why before retrying
        - Different errors require different recovery strategies
    - id: ENG-REL-001
      name: Pre-Operation Verification
      justifications:
        - Verify resources exist before operating on them
        - Check paths and permissions proactively
  verified: 2026-03-31
  rationale: >
    Tool failures are common during development. Structured recovery
    ensures errors are diagnosed before retrying and prevents spinning
    on unsolvable problems.
---

# Tool Failure Recovery

When a tool call fails, diagnose before retrying.

## Quick Diagnosis

| Error Type | Likely Cause | Recovery Action |
|------------|--------------|-----------------|
| `file not found` | Wrong path | Glob to find correct path |
| `permission denied` | Protected file/directory | Check if path is allowed |
| `command failed` | Missing dependency or wrong args | Check error output carefully |
| `timeout` | Long-running operation | Consider chunking or background |
| `connection refused` | Service not running | Verify service is up |

## Two-Attempt Rule

1. **First attempt fails**: Diagnose the error, adjust approach
2. **Second attempt fails**: Escalate to user or try fundamentally different approach
3. **Don't**: Retry the same command hoping for different results

## Before Retrying

```
[ ] Did I read the error message carefully?
[ ] Do I understand WHY it failed?
[ ] Is my next attempt meaningfully different?
[ ] Should I verify preconditions first (file exists, service running)?
```

## Common Recovery Patterns

**File not found:**
```
1. Glob("**/*filename*") to find actual location
2. Check for typos in path
3. Verify the file was created by previous step
```

**Permission denied:**
```
1. Check if path is in allowed directories
2. Don't try to chmod - ask user if access is needed
```

**Command failed:**
```
1. Read the full error output
2. Check if required tools are installed
3. Verify arguments match expected format
```
