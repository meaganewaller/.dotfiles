---
layout: page
title: Friction Taxonomy
permalink: /friction-taxonomy/
updated_at: 2026-03-10
---

# Friction Taxonomy

How tool failures are classified for pattern detection.

## Overview

When a tool fails during a Claude Code session, the `skill-gap-detector.sh` hook classifies the error into a hierarchical taxonomy. This classification enables:

- **Pattern detection** across sessions
- **Skill gap identification** over time
- **Deliberate practice recommendations**
- **Context-aware hints** based on file type and location
- **Ephemeral file suppression** to reduce noise from expected failures

## Primary Domains

{% mermaid %}
flowchart TB
    F[Friction] --> syntax[syntax<br/>Parse errors]
    F --> type[type<br/>Type mismatches]
    F --> dependency[dependency<br/>Missing packages]
    F --> permission[permission<br/>Access denied]
    F --> network[network<br/>Connection errors]
    F --> state[state<br/>File not found]
    F --> config[config<br/>Env vars]
    F --> testing[testing<br/>Test failures]
    F --> build[build<br/>Compilation errors]
{% endmermaid %}

## Domain Details

### State

The most common friction domain. Occurs when operations encounter unexpected system state.

{% mermaid %}
flowchart LR
    A[state] --> B[file-not-found]
    A --> C[resource-limit]
    A --> D[command-file-missing]
    A --> E[type-mismatch]
    A --> F[conflict]
    A --> G[identity]
    A --> H[command-failed]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `file-not-found` | `state:file-not-found` | ENOENT, missing files |
| `resource-limit` | `state:resource-limit` | File too large, token limits |
| `command-file-missing` | `state:command-missing-file` | Exit code + missing file |
| `type-mismatch` | `state:dir-file-mismatch` | EISDIR, expected file got directory |
| `conflict` | `state:conflict` | Stale locks, concurrent modifications |
| `identity` | `state:file-identity` | Symlink loops, same file errors |
| `command-failed` | `state:command-exit-nonzero` | Non-zero exit code (fallback) |

**Common causes:**
- Working with newly created files before they exist
- Operations on large files without pagination
- Concurrent access to shared resources

**Practice recommendations:**
- Add existence checks before file operations
- Use chunked reads for files > 1000 lines
- Implement retry logic with backoff

### Syntax

Parse errors from malformed input.

{% mermaid %}
flowchart LR
    A[syntax] --> B[parse]
    A --> C[json]
    A --> D[yaml]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `parse` | `syntax:parse-error` | Missing brackets, unterminated strings |
| `json` | `syntax:json-parse` | Trailing commas, unquoted keys |
| `yaml` | `syntax:yaml-parse` | Bad indentation, tabs in YAML |

**Practice recommendations:**
- Validate JSON/YAML before writing
- Use linters during editing
- Double-check multiline strings

### Type

Type system complaints.

{% mermaid %}
flowchart LR
    A[type] --> B[typescript]
    A --> C[ruby-sorbet]
    A --> D[rust-ownership]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `typescript` | `type:typescript` | Type mismatches, assignment errors |
| `ruby-sorbet` | `type:sorbet` | Sorbet type violations |
| `rust-ownership` | `type:rust-borrow` | Borrow checker, lifetime errors |

**Practice recommendations:**
- Add type annotations at boundaries
- Use strict null checks
- Write types before implementation

### Dependency

Package and module resolution failures.

{% mermaid %}
flowchart LR
    A[dependency] --> B[ruby-bundler]
    A --> C[node-npm]
    A --> D[rust-cargo]
    A --> E[python-module]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `ruby-bundler` | `dependency:bundler` | Missing gems, Gemfile.lock issues |
| `node-npm` | `dependency:npm` | Missing packages, peer deps |
| `rust-cargo` | `dependency:cargo` | Missing crates, Cargo.toml errors |
| `python-module` | `dependency:python-import` | ModuleNotFoundError, ImportError |

**Practice recommendations:**
- Run install commands after dependency changes
- Keep lock files in sync
- Use exact versions for critical deps

### Permission

Access control failures.

{% mermaid %}
flowchart LR
    A[permission] --> B[filesystem]
    A --> C[auth]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `filesystem` | `permission:fs-access` | EACCES, EPERM, read-only filesystem |
| `auth` | `permission:auth` | 401/403, invalid tokens, expired credentials |

**Practice recommendations:**
- Check credentials before operations
- Use least-privilege principles
- Verify file permissions

### Network

Connection and communication failures.

{% mermaid %}
flowchart LR
    A[network] --> B[connection]
    A --> C[timeout]
    A --> D[ssl]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `connection` | `network:connection` | ECONNREFUSED, DNS failures, unreachable |
| `timeout` | `network:timeout` | ETIMEDOUT, deadline exceeded |
| `ssl` | `network:ssl` | Certificate errors, SSL handshake failures |

**Practice recommendations:**
- Add timeout handling
- Implement retry with exponential backoff
- Verify connectivity before operations

### Config

Environment and configuration issues.

{% mermaid %}
flowchart LR
    A[config] --> B[env-var]
    A --> C[rails-autoload]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `env-var` | `config:env-var` | Missing environment variables |
| `rails-autoload` | `config:rails-autoload` | Zeitwerk errors, uninitialized constants |

**Common causes:**
- Missing .env files
- Wrong environment active
- File path doesn't match Rails constant naming

**Practice recommendations:**
- Document required env vars
- Use config validation at startup
- Run `zeitwerk:check` for Rails autoloading issues

### Testing

Test execution failures.

{% mermaid %}
flowchart LR
    A[testing] --> B[assertion]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `assertion` | `testing:assertion` | RSpec, Jest, pytest failures |

**Common causes:**
- Actual bugs in code
- Stale fixtures
- Race conditions

**Practice recommendations:**
- Fix tests immediately
- Use deterministic fixtures
- Isolate flaky tests

### Build

Compilation and bundling failures.

{% mermaid %}
flowchart LR
    A[build] --> B[bundler]
    A --> C[native]
{% endmermaid %}

| Subdomain | Signals | Triggers |
|-----------|---------|----------|
| `bundler` | `build:bundler` | Webpack, Vite, esbuild, Rollup errors |
| `native` | `build:native-compile` | gcc, clang, Make, CMake errors |

**Common causes:**
- Syntax errors preventing compilation
- Missing build dependencies
- ESM/CJS compatibility issues

**Practice recommendations:**
- Run builds frequently
- Keep build tools updated
- Use CI to catch cross-platform issues

## File Context Classification

Beyond domain classification, the skill-gap-detector identifies the *context* of failures based on file paths. This enables context-specific hints.

{% mermaid %}
flowchart TD
    A[File Path] --> B{Match pattern}
    B --> C[subagent-session]
    B --> D[session-log]
    B --> E[telemetry-log]
    B --> F[hook-script]
    B --> G[cue-file]
    B --> H[tradeoff-marker]
    B --> I[claude-internal]
    B --> J[user-file]
{% endmermaid %}

| Context | Path Pattern | Example Hint |
|---------|-------------|--------------|
| `subagent-session` | `~/.claude/projects/*/subagents/*` | "Subagent may have completed" |
| `session-log` | `~/.claude/projects/*.jsonl` | "Use grep or offset/limit" |
| `telemetry-log` | `~/.claude/dev-os-events.jsonl` | "Use tail -100 instead" |
| `hook-script` | `~/.claude/hooks/*` | Standard hints |
| `cue-file` | `~/.claude/cues/*` | Standard hints |
| `tradeoff-marker` | `~/.claude/pending-tradeoffs/*` | "Marker may be processed" |
| `claude-internal` | `~/.claude/*` | Standard hints |
| `user-file` | Everything else | Standard hints |

## Ephemeral File Suppression

Some "file not found" errors are expected behavior, not friction:

- **Subagent sessions** are cleaned up after completion
- **Tradeoff markers** are processed and removed

These are silently skipped to reduce noise in friction metrics.

## Pattern Detection

The weekly review aggregates friction by domain and subdomain to identify patterns:

```
### By Domain
- state: 511
- unknown: 48
- dependency: 3

### By Subdomain
- state:file-not-found: 232
- state:resource-limit: 226
- state:command-failed: 41
```

High concentrations in a domain indicate skill gaps that warrant deliberate practice.

## Escalation

When the same friction domain appears repeatedly (3+ times), `friction-escalator.sh` surfaces a warning at the start of your next session:

```
SessionStart hook additional context:
Repeated friction in [state]: 20 hits.
Subdomains: file-not-found(10) resource-limit(7) command-failed(3)
Hint: Command returned non-zero exit code; check if target exists...
```

This creates a feedback loop for improvement.

## Classification Logic

The `skill-gap-detector.sh` hook uses pattern matching on error messages with priority ordering:

```bash
# Helper functions
add_hint() { HINTS+=("$1"); }
add_signal() { SIGNALS+=("$1"); }
set_domain() {
  if [[ "$DOMAIN" == "unknown" ]]; then  # First match wins
    DOMAIN="$1"
    SUBDOMAIN="${2:-}"
  fi
}

# Priority 1: File not found (most common)
if echo "$TEXT" | grep -qiE "file does not exist|no such file|ENOENT"; then
  set_domain "state" "file-not-found"
  add_signal "state:file-not-found"
  # Context-specific hints based on FILE_CONTEXT
fi

# Priority 2: Resource limits
if echo "$TEXT" | grep -qiE "too large|size limit|token limit"; then
  set_domain "state" "resource-limit"
  add_signal "state:resource-limit"
fi

# ... additional patterns in priority order
```

The classification outputs:
- **domain**: Primary error category
- **subdomain**: Specific error type within domain
- **signals**: Machine-readable tags for aggregation
- **hints**: Human-readable suggestions
- **context**: File metadata when relevant

Unrecognized errors default to `domain: unknown`.

## Adding Custom Patterns

To improve classification accuracy, extend the pattern matching in `skill-gap-detector.sh`:

```bash
# Add in the appropriate section (SYNTAX, TYPE, DEPENDENCY, etc.)
if echo "$TEXT" | grep -qiE "your specific pattern"; then
  set_domain "appropriate_domain" "specific_subdomain"
  add_signal "domain:subdomain"
  add_hint "Helpful suggestion for this error type."
fi
```

**Guidelines:**
- Place patterns in the correct domain section
- Use `set_domain` (first match wins)
- Add a signal for aggregation
- Include actionable hints
- Test with actual error messages

## Event Output

Each friction event is logged with rich context:

```json
{
  "timestamp": "2026-03-10T15:30:00Z",
  "tool_name": "Read",
  "file_paths": ["/path/to/large-file.jsonl"],
  "session_id": "abc123",
  "is_subagent": false,
  "domain": "state",
  "subdomain": "resource-limit",
  "error_excerpt": "File content exceeds maximum...",
  "hints": ["Use tail -100 or grep instead"],
  "signals": ["state:resource-limit"],
  "context": {
    "file_context": "telemetry-log",
    "file_type": "jsonl-log",
    "file_exists": true,
    "file_size_kb": 2048
  }
}
```

This structured output enables:
- Weekly aggregation by domain/subdomain
- Repeat pattern detection (same tool + subdomain)
- Context-aware analysis (which file types cause friction)
- Subagent vs main agent comparison

---

Previous: [Data Capture](/data-capture/) | Next: [Review Pipeline](/review-pipeline/)
