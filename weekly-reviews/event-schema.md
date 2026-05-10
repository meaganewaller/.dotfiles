---
layout: page
title: Event Schema
permalink: /event-schema/
updated_at: 2026-03-10
---

# Event Schema

Structure of events captured by the Dev OS telemetry system.

## Primary Event Log

All events are appended to `~/.claude/dev-os-events.jsonl` in JSON Lines format (one JSON object per line).

### Base Structure

Every event contains:

```json
{
  "timestamp": "2026-02-27T10:30:00Z",
  "session_id": "abc123",
  "event_type": "tool_write",
  "payload": { ... }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the event occurred |
| `session_id` | string | Unique identifier for the Claude Code session |
| `event_type` | string | Type of event (see below) |
| `payload` | object | Event-specific data |

## Event Types

### tool_write

Emitted when a file is created or modified.

```json
{
  "event_type": "tool_write",
  "payload": {
    "files": ["/path/to/file.rb"],
    "change_type": "refactor",
    "risk_level": "low",
    "skill_domains": ["application development"]
  }
}
```

| Payload Field | Type | Values |
|---------------|------|--------|
| `files` | string[] | Paths to files written |
| `change_type` | string | `feature`, `fix`, `refactor`, `test`, `infra`, `docs` |
| `risk_level` | string | `low`, `medium`, `high` |
| `skill_domains` | string[] | Classification of work type |

### tool_failure

Emitted when a tool execution fails.

```json
{
  "event_type": "tool_failure",
  "payload": {
    "tool": "Read",
    "file_path": "/path/to/missing.rb",
    "file_context": "user-file",
    "file_type": "ruby",
    "domain": "state",
    "subdomain": "file-not-found",
    "hints": ["Verify the file path exists; check for typos or stale references"],
    "friction_domain": {
      "domain": "state",
      "subdomain": "file-not-found",
      "signals": ["state:file-not-found"]
    },
    "error_excerpt": "No such file: /path/to/missing.rb",
    "repeat_count": 0,
    "is_subagent": false,
    "context": {
      "file_context": "user-file",
      "file_type": "ruby",
      "file_exists": false,
      "file_is_dir": false,
      "file_size_kb": 0
    }
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `tool` | string | Which tool failed |
| `file_path` | string | Path to file (if applicable) |
| `file_context` | string | Context classification (see below) |
| `file_type` | string | File extension type |
| `domain` | string | Top-level friction category |
| `subdomain` | string | Specific friction type |
| `hints` | string[] | Context-aware suggestions |
| `friction_domain` | object | Structured domain with signals |
| `error_excerpt` | string | First 800 chars of error |
| `repeat_count` | number | Times this pattern repeated recently |
| `is_subagent` | boolean | Whether in subagent context |
| `context` | object | File metadata (for Read failures) |

**File context values:**
- `subagent-session` - Subagent session files
- `session-log` - Project session logs
- `telemetry-log` - Dev OS event logs
- `hook-script` - Hook scripts
- `cue-file` - Cue definitions
- `tradeoff-marker` - Pending tradeoff markers
- `claude-internal` - Other ~/.claude files
- `user-file` - User project files

See [Friction Taxonomy](/friction-taxonomy/) for domain/subdomain hierarchy.

### large_change

Emitted when a diff exceeds 250 lines.

```json
{
  "event_type": "large_change",
  "payload": {
    "file_path": "/path/to/large_file.rb",
    "lines_added": 180,
    "lines_removed": 95,
    "total_lines": 275
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `file_path` | string | File with large change |
| `lines_added` | number | Lines added |
| `lines_removed` | number | Lines removed |
| `total_lines` | number | Total lines changed |

### reversal

Emitted when recent work is undone.

```json
{
  "event_type": "reversal",
  "payload": {
    "reverted_file": "/path/to/file.rb",
    "lines_removed": 75,
    "lines_added": 10,
    "reason": "Exploration rolled back"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `reverted_file` | string | File being reverted |
| `lines_removed` | number | Lines deleted |
| `lines_added` | number | Lines added (typically small) |
| `reason` | string | Optional explanation |

### decision_tradeoff

Emitted when architectural decisions are documented.

```json
{
  "event_type": "decision_tradeoff",
  "payload": {
    "summary": "Chose jq over Python for JSON processing",
    "options": ["jq", "Python", "Node.js"],
    "tradeoffs": [
      "jq: shell-native, no dependencies, but limited logic",
      "Python: powerful, but adds dependency"
    ],
    "principles": ["convention over configuration", "explicit over implicit"]
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `summary` | string | Brief description of decision |
| `options` | string[] | Alternatives considered |
| `tradeoffs` | string[] | Pros/cons of each option |
| `principles` | string[] | Architectural principles invoked |

### test_run

Emitted when tests are executed.

```json
{
  "event_type": "test_run",
  "payload": {
    "passed": true,
    "tests_run": 47,
    "tests_passed": 47,
    "tests_failed": 0,
    "duration_seconds": 12.5,
    "test_files": ["spec/models/user_spec.rb"]
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `passed` | boolean | Overall pass/fail |
| `tests_run` | number | Total tests executed |
| `tests_passed` | number | Tests that passed |
| `tests_failed` | number | Tests that failed |
| `duration_seconds` | number | Execution time |
| `test_files` | string[] | Files tested |

### task_completed

Emitted when a task is marked complete.

```json
{
  "event_type": "task_completed",
  "payload": {
    "task_id": "task-123",
    "task_subject": "Implement user authentication",
    "validation_checks": {
      "tests_passing": true,
      "linting_clean": true
    }
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `task_id` | string | Task identifier |
| `task_subject` | string | Task description |
| `validation_checks` | object | Gate validation results |

### dependency_change

Emitted when dependency files are modified.

```json
{
  "event_type": "dependency_change",
  "payload": {
    "file": "Gemfile",
    "added": ["rails", "pg"],
    "removed": ["sqlite3"],
    "updated": []
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `file` | string | Dependency file changed |
| `added` | string[] | New dependencies |
| `removed` | string[] | Removed dependencies |
| `updated` | string[] | Updated dependencies |

### cue_fired

Emitted when a cue is injected (legacy format, see also `cue_matched`).

```json
{
  "event_type": "cue_fired",
  "payload": {
    "cue_id": "commit",
    "trigger_type": "prompt",
    "has_macro": false,
    "query": "commit my changes"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `cue_id` | string | Cue identifier |
| `trigger_type` | string | `prompt`, `command`, or `file` |
| `has_macro` | boolean | Whether macro was executed |
| `query` | string | Text that triggered the cue |

**Note:** Newer hooks emit `cue_matched` with richer match details.

### session_duration

Emitted periodically to track session length and archetype.

```json
{
  "event_type": "session_duration",
  "payload": {
    "duration_minutes": 145,
    "archetype": "long",
    "has_task_list": true
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `duration_minutes` | number | Minutes since session start |
| `archetype` | string | Duration category (see below) |
| `has_task_list` | boolean | Whether task list is active |

**Duration categories:**
| Category | Duration | Guidance |
|----------|----------|----------|
| `quick` | < 15 min | Short task |
| `short` | 15-60 min | Focused work |
| `medium` | 1-3 hours | Consider task list |
| `long` | 3-8 hours | Break checkpoints |
| `marathon` | 8+ hours | High compaction risk |

See [Session Archetype](/glossary/session-archetype/) for archetype definitions.

### session_health

Emitted at compaction to capture session quality metrics.

```json
{
  "event_type": "session_health",
  "payload": {
    "duration_minutes": 145,
    "archetype": "marathon",
    "trigger": "pre_compact"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `duration_minutes` | number | Session duration at snapshot |
| `archetype` | string | Session archetype |
| `trigger` | string | What triggered the snapshot (`pre_compact`) |

See [Session Health](/glossary/session-health/) for the composite health metric.

### principle_activated

Emitted when a principle is first invoked in a session.

```json
{
  "event_type": "principle_activated",
  "payload": {
    "principle": "model-first",
    "context": "",
    "activation": "first_invocation"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `principle` | string | Principle identifier |
| `context` | string | Optional surrounding context |
| `activation` | string | Always `first_invocation` |

### principle_reinforced

Emitted when an active principle is re-surfaced before a tool operation.

```json
{
  "event_type": "principle_reinforced",
  "payload": {
    "file_path": "/app/models/user.rb",
    "tool": "Write",
    "principles_reinforced": ["model-first"],
    "reinforcement_count": 1
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `file_path` | string | File being written/edited |
| `tool` | string | Tool being used (`Write` or `Edit`) |
| `principles_reinforced` | string[] | Principles re-surfaced |
| `reinforcement_count` | number | Total reinforcements this session |

See [Principle Activation](/glossary/principle-activation/) for the activation lifecycle.

### domain_modeling

Emitted when prompts indicate upfront design work.

```json
{
  "event_type": "domain_modeling",
  "payload": {
    "prompt_snippet": "what entities do we need for...",
    "trigger": "prompt_pattern"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `prompt_snippet` | string | First 100 chars of prompt |
| `trigger` | string | How it was detected (`prompt_pattern`) |

See [Domain Modeling](/glossary/domain-modeling/) for correlation with reversals.

### session_start

Emitted when a session begins.

```json
{
  "event_type": "session_start",
  "payload": {
    "start_time": "2026-03-10T10:00:00Z"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `start_time` | ISO 8601 | When the session started |

### session_end

Emitted when a session terminates.

```json
{
  "event_type": "session_end",
  "payload": {
    "end_time": "2026-03-10T12:30:00Z",
    "start_time": "2026-03-10T10:00:00Z",
    "duration_seconds": 9000,
    "duration_minutes": 150,
    "duration_category": "medium"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `end_time` | ISO 8601 | When the session ended |
| `start_time` | ISO 8601 | When the session started (if known) |
| `duration_seconds` | number | Total session duration |
| `duration_minutes` | number | Duration in minutes |
| `duration_category` | string | `quick`, `short`, `medium`, `long`, or `marathon` |

### skill_invoked

Emitted when a skill is invoked via the Skill tool.

```json
{
  "event_type": "skill_invoked",
  "payload": {
    "skill": "weekly-review",
    "args": null
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `skill` | string | Skill name |
| `args` | string | Arguments passed (if any) |

### context_compact

Emitted when context compaction occurs.

```json
{
  "event_type": "context_compact",
  "payload": {
    "transcript_bytes": 450000,
    "message_count": 85,
    "compaction_number": 2,
    "reason": "context_window_limit"
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `transcript_bytes` | number | Size of transcript being compacted |
| `message_count` | number | Approximate message count |
| `compaction_number` | number | Which compaction this session (1, 2, 3...) |
| `reason` | string | Why compaction occurred |

### cue_matched

Emitted when cues are matched and injected.

```json
{
  "event_type": "cue_matched",
  "payload": {
    "cues": ["file-verification", "testing"],
    "trigger_type": "prompt",
    "prompt_snippet": "let's update the test file...",
    "match_details": [
      {
        "cue": "file-verification",
        "match_type": "pattern"
      },
      {
        "cue": "testing",
        "match_type": "vocabulary"
      }
    ]
  }
}
```

| Payload Field | Type | Description |
|---------------|------|-------------|
| `cues` | string[] | Cues that matched |
| `trigger_type` | string | `prompt`, `command`, or `file` |
| `prompt_snippet` | string | First 100 chars of trigger |
| `match_details` | object[] | Per-cue match information |

**Match types:**
- `pattern` - Regex pattern matched
- `vocabulary` - Vocabulary word matched
- `semantic` - NCD similarity matched

## Supporting Log Files

### impact-log.jsonl

Detailed file change tracking:

```json
{
  "timestamp": "2026-02-27T10:30:00Z",
  "file_paths": ["/path/to/file.rb"],
  "change_type": "refactor",
  "skill_domains": ["application development"],
  "risk_level": "low"
}
```

### skill-friction-log.jsonl

Error classification for pattern detection:

```json
{
  "timestamp": "2026-02-27T10:30:00Z",
  "tool_name": "Read",
  "file_paths": ["/path/to/missing.rb"],
  "session_id": "abc123",
  "is_subagent": false,
  "domain": "state",
  "subdomain": "file-not-found",
  "error_excerpt": "No such file...",
  "hints": ["Verify the file path exists"],
  "signals": ["state:file-not-found"],
  "context": {
    "file_context": "user-file",
    "file_type": "ruby",
    "file_exists": false
  }
}
```

### hook-health.jsonl

Hook execution monitoring:

```json
{
  "timestamp": "2026-03-10T15:30:00Z",
  "hook": "impact-extractor",
  "status": "success",
  "duration_ms": 12,
  "error": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When hook executed |
| `hook` | string | Hook name (from `hook_register`) |
| `status` | string | `success` or `failure` |
| `duration_ms` | number | Execution time in milliseconds |
| `error` | string | Error message (if failed) |

Use `hook-health.sh` CLI to query this log (see [Hooks & Cues](/hooks-and-cues/#hook-health-cli)).

## Querying Events

**Important:** Event logs can grow large. Always use `tail` or time filtering to avoid loading entire files.

### Recent events

```bash
# Last 20 events (safe)
tail -20 ~/.claude/dev-os-events.jsonl | jq .

# Last 100 events of specific type
tail -500 ~/.claude/dev-os-events.jsonl | jq 'select(.event_type == "tool_failure")'
```

### Filter by type

```bash
# Use grep + jq for large files (avoids loading all into memory)
grep '"event_type":"tool_failure"' ~/.claude/dev-os-events.jsonl | tail -50 | jq .
```

### Count by type (recent)

```bash
tail -1000 ~/.claude/dev-os-events.jsonl | jq -s '
  group_by(.event_type)
  | map({type: .[0].event_type, count: length})
  | sort_by(-.count)'
```

### Last 7 days

```bash
# macOS
SINCE=$(date -v-7d +%Y-%m-%d)
# Linux
# SINCE=$(date -d '7 days ago' +%Y-%m-%d)

tail -5000 ~/.claude/dev-os-events.jsonl | jq -s --arg since "$SINCE" '
  [.[] | select(.timestamp >= $since)]'
```

### Friction by domain

```bash
grep '"event_type":"tool_failure"' ~/.claude/dev-os-events.jsonl | tail -500 | jq -s '
  group_by(.payload.domain)
  | map({domain: .[0].payload.domain, count: length})
  | sort_by(-.count)'
```

### Hook health summary

```bash
# Use the CLI
~/.claude/hooks/hook-health.sh           # 24h summary
~/.claude/hooks/hook-health.sh 168       # 7-day summary
~/.claude/hooks/hook-health.sh --failures
```

## Log Rotation

### Automatic Guards

Hooks use `guard_log_size` to prevent unbounded growth:

```bash
source "$HOME/.claude/hooks/validate-path.sh"

# Warn and rotate if log exceeds 50MB
if ! guard_log_size "$LOG_FILE" 50; then
  # Rotate: keep last 1000 entries
  tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
```

### Manual Rotation

```bash
# Keep last 10000 events
tail -10000 ~/.claude/dev-os-events.jsonl > /tmp/events.tmp
mv /tmp/events.tmp ~/.claude/dev-os-events.jsonl
```

### Archive Before Rotation

```bash
# Archive then rotate
mkdir -p ~/.claude/archive
cp ~/.claude/dev-os-events.jsonl ~/.claude/archive/events-$(date +%Y%m%d).jsonl
tail -10000 ~/.claude/dev-os-events.jsonl > /tmp/events.tmp
mv /tmp/events.tmp ~/.claude/dev-os-events.jsonl
```

### Recommended Rotation Schedule

| Log File | Max Size | Keep Entries |
|----------|----------|--------------|
| `dev-os-events.jsonl` | 50MB | 10,000 |
| `skill-friction-log.jsonl` | 50MB | 1,000 |
| `impact-log.jsonl` | 20MB | 5,000 |
| `hook-health.jsonl` | 10MB | 5,000 |

## Log File Locations

| File | Purpose |
|------|---------|
| `~/.claude/dev-os-events.jsonl` | Primary event stream |
| `~/.claude/skill-friction-log.jsonl` | Friction/error details |
| `~/.claude/impact-log.jsonl` | File change tracking |
| `~/.claude/hook-health.jsonl` | Hook execution monitoring |

---

Previous: [Hooks & Cues](/hooks-and-cues/) | [Back to How It Works](/how-it-works/)
