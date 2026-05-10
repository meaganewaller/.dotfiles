---
layout: glossary-term
term: Loop Detection
short: Identifying exploration loops and progress stagnation
category: analysis
related:
  - reversal
  - two-attempt-rule
  - friction
  - session-health
aliases:
  - loop detector
  - progress stagnation
  - file thrashing
---

The system for detecting when work is stuck in unproductive cycles—repeatedly editing files, encountering the same errors, or making no measurable progress.

## Loop Signals

The `loop-detector` hook watches for four patterns:

### 1. Progress Stagnation

No measurable progress over the last 25 actions.

```bash
# Progress scoring
+3  success/passed/completed in output
-2  failed/error/exception in output
+1  Write or Edit operation
```

If cumulative score ≤ 0 over the window: **stagnation warning**.

### 2. Repeated Errors

Same error fingerprint appearing 3+ times.

```bash
# Error fingerprinting (first 10 chars of MD5)
fingerprint_error() {
  grep -iE "error|failed|exception" | head -n1 | md5sum | cut -c1-10
}
```

If same fingerprint repeats 3+ times: **error loop warning**.

### 3. File Thrashing

Same file edited 6+ times in recent operations.

```bash
# Track recent file edits
if (( thrash_count >= 6 )); then
  echo "[LOOP WARNING] File edited $thrash_count times recently."
fi
```

### 4. Read Scanning

15+ reads with no writes—likely scanning without acting.

```bash
if (( reads >= 15 && writes == 0 )); then
  echo "[LOOP WARNING] $reads reads with no writes"
fi
```

## State Tracking

Loop detector maintains rolling state:

```json
{
  "history": [],
  "progress": [3, -2, 1, 1, -2, ...],
  "files": ["/path/a.rb", "/path/a.rb", ...],
  "errors": ["a1b2c3d4e5", "a1b2c3d4e5", ...],
  "reads": 12,
  "writes": 2
}
```

State is stored in `/tmp/claude-progress-loop.json` with file locking for concurrent access.

## Thresholds

| Signal | Threshold | Rationale |
|--------|-----------|-----------|
| Progress window | 25 actions | Long enough for meaningful work |
| Error repeat | 3 occurrences | Once is error, twice is coincidence, three is pattern |
| File thrash | 6 edits | Allows for iterative refinement |
| Read scan | 15 reads, 0 writes | Exploration should produce output |

## Intervention

Loop detection emits warnings to stderr, visible in session:

```
[LOOP WARNING] No measurable progress over last 25 actions.
[LOOP WARNING] Same error repeating 4 times.
[LOOP WARNING] File "user.rb" edited 7 times recently.
```

These warnings prompt reflection without blocking. Combined with the Two-Attempt Rule, they create natural pause points.

## Relationship to Recovery

```
Loop Detection (observation)
        ↓
    Warning emitted
        ↓
Recovery Cue (intervention)
        ↓
Two-Attempt Rule (decision)
```

Loop detection identifies the pattern. The recovery system provides the intervention.

## Telemetry

Loop warnings can be correlated with:
- Session duration (longer sessions = more loops?)
- Friction domains (which error types cause loops?)
- Reversal rate (do loops predict reversals?)

## Configuration

Thresholds can be tuned in the hook:

```bash
WINDOW=25        # Progress window size
ERROR_LOOP=3     # Error repeat threshold
FILE_THRASH=6    # File edit threshold
READ_LIMIT=15    # Read scan threshold
```

## In Weekly Reviews

- **Loop warnings**: Count by type
- **Correlation**: Loops vs. session duration
- **Resolution**: How loops were broken (pivot, escalate, persist)

## See Also

- `~/.claude/hooks/PostToolUse/loop-detector.sh`
- `~/.claude/cues/recovery/cue.md`
- `~/.claude/principles/recovery-principles.md`
