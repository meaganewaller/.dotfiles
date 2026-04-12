# Reliability Policy

## Purpose

Establish practices for building reliable systems that handle errors gracefully and operate predictably.

## Principles

### 1. Verify Before Acting

Check that resources exist before operating on them.

**Why:** Pre-verification:
- Provides clear error messages
- Prevents partial operations
- Enables graceful degradation

### 2. Idempotent Operations

Design operations to be safely repeatable.

**Why:** Idempotency:
- Enables safe retries
- Simplifies error recovery
- Supports distributed systems

### 3. Explicit Error Handling

Handle expected error cases explicitly rather than relying on generic catch-alls.

**Why:** Explicit handling:
- Documents known failure modes
- Enables appropriate recovery
- Prevents swallowing important errors

### 4. Resource Cleanup

Ensure resources are released even when errors occur.

**Why:** Cleanup guarantees:
- Prevent resource leaks
- Maintain system stability
- Enable long-running processes

### 5. Graceful Degradation

When components fail, maintain partial functionality when safe.

**Why:** Degradation:
- Improves user experience
- Maintains critical functions
- Buys time for recovery

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-REL-001 | Pre-Operation Verification |
| ENG-REL-002 | Idempotent Design |
| ENG-REL-003 | Explicit Error Handling |
| ENG-REL-004 | Resource Cleanup Guarantee |
| ENG-REL-005 | Graceful Degradation |

## Related Cues

- `file-verification/cue.md` - Triggered on file operations
- `recovery/cue.md` - Triggered on failure recovery
