# Claude Code hooks

This directory holds **hook scripts** that run in response to Claude Code events. Hooks are wired in `settings/common/hooks.jsonc`; when you run `mise run claude`, those settings determine which scripts run and for which tools/events.

## Layout

```
hooks/
├── README.md                  # this file
└── common/                    # shared hooks (used by all profiles)
    ├── validate-path.sh       # shared utilities: path validation, health monitoring
    ├── dev-os-emit.sh         # helper: append events to .claude/dev-os-events.jsonl
    ├── hook-health.sh         # CLI: check hook execution health
    ├── match-cues.sh          # find cues by regex + semantic matching
    ├── show-cue.sh            # output cue with marker gating + macro support
    ├── semantic-match.sh      # gzip NCD similarity matching
    │
    ├── SessionStart/
    │   ├── clear-cue-markers.sh
    │   ├── session-context-injector.sh
    │   ├── session-start-tracker.sh
    │   ├── friction-escalator.sh
    │   ├── hook-health-reporter.sh
    │   └── branch-staleness-check.sh
    │
    ├── UserPromptSubmit/
    │   ├── cue-injector-prompt.sh
    │   ├── state-triggers.sh
    │   ├── idea-classifier.sh
    │   └── session-duration-monitor.sh
    │
    ├── PreToolUse/
    │   ├── mark-tasks-active.sh      # TaskCreate
    │   ├── cue-task-stash.sh         # Task
    │   ├── cue-injector-bash.sh      # Bash
    │   ├── git-guard.sh              # Bash - block dangerous git ops
    │   ├── block-destructive.sh      # Bash - block rm -rf, curl|bash
    │   ├── exfiltration-check.sh     # Bash - block data exfiltration
    │   ├── uncommitted-change-guard.sh # Write|Edit - warn on dirty files
    │   ├── secret-scanner.sh         # Write|Edit - block secrets in code
    │   ├── cue-injector-file.sh      # Write|Edit
    │   ├── layering-guard.sh         # Write|Edit
    │   ├── principle-reinforcer.sh   # Write|Edit
    │   ├── large-file-guard.sh       # Read
    │   ├── bulk-operation-estimator.sh  # Glob|Grep
    │   └── agent-spawn-tracker.sh    # Agent - track agent spawns
    │
    ├── PostToolUse/
    │   ├── loop-detector.sh          # * (all tools)
    │   ├── principle-activator.sh    # * (all tools)
    │   ├── impact-extractor.sh       # Write|Edit
    │   ├── large-diff-escalator.sh   # Write|Edit
    │   ├── dependency-change-detector.sh  # Write|Edit
    │   ├── reversal-detector.sh      # Write|Edit
    │   ├── async-test-runner.sh      # Write|Edit (async)
    │   ├── ai-guardrails.sh          # Write|Edit - AI pitfall detection
    │   ├── skill-usage-tracker.sh    # Skill
    │   ├── read-tracker.sh           # Read
    │   └── resource-limit-catcher.sh # Read
    │
    ├── PostToolUseFailure/
    │   └── skill-gap-detector.sh
    │
    ├── SubagentStart/
    │   └── cue-inject-subagent.sh
    │
    ├── Stop/
    │   ├── response-topics-writer.sh
    │   ├── hard-stop-test-blocker.sh
    │   ├── leverage-evaluator.sh
    │   └── cost-tracker.sh           # Track token costs
    │
    ├── TaskCompleted/
    │   └── task-gate.sh
    │
    ├── PreCompact/
    │   ├── context-compact-tracker.sh
    │   └── pre-compact-snapshot.sh
    │
    ├── SessionEnd/
    │   ├── session-end-tracker.sh
    │   └── learning-suggestion-generator.sh
    │
    ├── WorktreeCreate/
    │   └── worktree-create-log.sh
    │
    └── WorktreeRemove/
        └── worktree-remove-log.sh
```

Event names match Claude Code’s hook events; scripts under each folder are invoked when that event fires (and when the optional **matcher** in `hooks.jsonc` matches, e.g. `Write|Edit`).

## How hooks are wired

- **Where**: `home/.claude/settings/common/hooks.jsonc` defines `hooks` with event names as keys.
- **Commands**: Each entry can run a `command` (script path), a `prompt`, or an `agent`. Script paths use `$CLAUDE_PROJECT_DIR` (project root).
- **Matchers**: Optional `matcher` limits the hook to certain tools or triggers (e.g. only after `Write` or `Edit`).
- **Order**: Scripts under the same event run in the order listed; `async: true` runs that script without blocking.

**Stop** runs a command first (`hard-stop-test-blocker.sh`), then a prompt gate. **SubagentStop** is defined entirely in the JSON (agent only).

**Paths:** Some hooks use the **project** `.claude/` (e.g. `session-context-injector` reads from the repo’s `.claude/`). Others use **`$HOME/.claude/`** for logs and outputs (e.g. `impact-log.jsonl`, `skill-friction-log.jsonl`, `dev-os-events.jsonl`, `learning-targets/`).

**Cues** live in `~/.claude/cues/<name>/cue.md` (and optionally `$PROJECT/.claude/cues/`). They are declarative guidance that fires when triggers match. Matching is done by `match-cues.sh` in priority order:

1. **Regex match**: `pattern:` (prompts), `commands:` (bash), `files:` (file paths)
2. **Vocabulary match**: Any word in `vocabulary:` field appears in query
3. **Semantic match**: Gzip NCD similarity to `description:` field (threshold: 0.65)

**Scope filtering**: Cues declare `scope: agent`, `scope: subagent`, or `scope: agent, subagent`. The `CUE_SCOPE_FILTER` env var controls which scopes to match.

**Macros**: Cues with `macro: prepend|append` and a `macro.sh` script get dynamic content injected before/after the cue body.

**Once-per-session gating**: Markers under `/tmp/.claude-devos-cue-*` prevent duplicate injection; `clear-cue-markers.sh` resets on SessionStart. `show-cue.sh` handles marker checking, macro execution, and content output.

## Event → script summary

| Event | Purpose |
|-------|---------|
| **SessionStart** | Initialize session context and clear markers |
| **UserPromptSubmit** | Match cues, track state, classify ideas |
| **PreToolUse** | Guard dangerous operations, inject contextual cues |
| **PostToolUse** | Track impact, detect large changes, run tests |
| **PostToolUseFailure** | Classify failures for learning |
| **SubagentStart** | Pass cue context to subagents |
| **Stop** | Gate on test status, track costs, evaluate leverage |
| **TaskCompleted** | Quality gate before task completion |
| **PreCompact** | Snapshot context before compaction |
| **SessionEnd** | Generate learning suggestions |

### Scripts by event

**SessionStart** (matcher: `startup|resume`)
- `clear-cue-markers.sh` - Reset once-per-session cue markers
- `session-context-injector.sh` - Inject recent impact/friction/journal
- `branch-staleness-check.sh` - Warn if branch is behind main
- `friction-escalator.sh` - Surface repeated friction patterns
- `hook-health-reporter.sh` - Warn if hooks are failing

**UserPromptSubmit**
- `cue-injector-prompt.sh` - Match prompt to contextual cues
- `state-triggers.sh` - Session-start and context-threshold triggers
- `idea-classifier.sh` - Capture opinions to idea vault

**PreToolUse**
- `mark-tasks-active.sh` (TaskCreate) - Set tasks-active marker
- `cue-task-stash.sh` (Task) - Stash cues for subagent
- `cue-injector-bash.sh` (Bash) - Inject cues for commands
- `git-guard.sh` (Bash) - Block dangerous git ops, enforce conventional commits
- `block-destructive.sh` (Bash) - Block rm -rf, curl|bash, force push
- `exfiltration-check.sh` (Bash) - Block data exfiltration patterns
- `uncommitted-change-guard.sh` (Write|Edit) - Warn before editing dirty files
- `secret-scanner.sh` (Write|Edit) - Block secrets (API keys, tokens, private keys)
- `cue-injector-file.sh` (Write|Edit) - Inject cues for file paths
- `layering-guard.sh` (Write|Edit) - Enforce architectural layering
- `principle-reinforcer.sh` (Write|Edit) - Reinforce engineering principles
- `large-file-guard.sh` (Read) - Block/warn on large file reads
- `bulk-operation-estimator.sh` (Glob|Grep) - Estimate operation scope
- `agent-spawn-tracker.sh` (Agent) - Track agent spawns, warn on sprawl

**PostToolUse** (matcher: `Write|Edit`)
- `impact-extractor.sh` - Log change type and skill domains
- `large-diff-escalator.sh` - Warn on >250 line changes
- `dependency-change-detector.sh` - Track dependency file changes
- `reversal-detector.sh` - Detect exploration reversals
- `async-test-runner.sh` - Run tests asynchronously
- `ai-guardrails.sh` - Detect AI dev pitfalls (missing tests, placeholders, hallucinated deps)

**PostToolUseFailure** (matcher: `Bash|Task|Read|Write|Edit|Glob|Grep|mcp__.*`)
- `skill-gap-detector.sh` - Classify failure for learning

**SubagentStart**
- `cue-inject-subagent.sh` - Inject stashed cue content

**Stop**
- `response-topics-writer.sh` - Write topics for next prompt
- `hard-stop-test-blocker.sh` - Block if last test failed
- `leverage-evaluator.sh` - Check session produced value
- `cost-tracker.sh` - Track token costs to `~/.claude/metrics/costs.jsonl`

**TaskCompleted**
- `task-gate.sh` - Run quality checks before completion

**PreCompact**
- `context-compact-tracker.sh` - Track compaction events
- `pre-compact-snapshot.sh` - Snapshot to `~/.claude/session-summaries/`

**SessionEnd**
- `session-end-tracker.sh` - Track session end
- `learning-suggestion-generator.sh` - Generate `~/.claude/learning-targets/latest.md`

## Helper scripts

- **`validate-path.sh`**
  Shared utility library sourced by most hooks. Provides:
  - Path constants: `CLAUDE_HOME`, `CLAUDE_EVENTS_LOG`, `CLAUDE_FRICTION_LOG`, `CLAUDE_IMPACT_LOG`, `CLAUDE_HOOK_HEALTH_LOG`
  - Validation functions: `validate_file_exists`, `validate_file_readable`, `validate_dir_exists`
  - Ensure functions: `ensure_dir_exists`, `ensure_file_exists`
  - Safe I/O: `safe_tail`, `safe_append`, `safe_emit`
  - Resource guards: `guard_diff_size`, `guard_file_size`, `guard_log_size`
  - **Hook health monitoring**: `hook_register`, `hook_success`, `hook_failure`, `hook_health_summary`
  - **Hook composition bus**: `hook_bus_init`, `hook_bus_put`, `hook_bus_get`, `hook_bus_has`, `hook_bus_list`, `hook_bus_cleanup`
  - **Project phase modes**: `get_project_mode`, `is_mode`, `require_mode`, `set_project_mode`
  - **Chunked file operations**: `is_large_file`, `file_line_count`, `read_file_chunked`, `read_lines`, `get_chunk_params`
  - **Progress indicators**: `show_progress`, `process_with_progress`, `process_files_batched`

- **`dev-os-emit.sh`**
  Used by other hooks to append a single JSON line to `.claude/dev-os-events.jsonl`.
  Usage: `echo '<hook stdin>' | ./dev-os-emit.sh <event_type> '<payload json>'`.
  Event types used: `test_run`, `task_completed`, `worktree_created`, `worktree_removed`, `large_change`, `dependency_change`, `reversal`, `tool_write`, `tool_failure`, `prompt_opinion`, `cue_fired`.

- **`hook-health.sh`**
  CLI tool to check hook execution health. Reads from `$HOME/.claude/hook-health.jsonl`.
  ```bash
  hook-health.sh              # 24-hour summary
  hook-health.sh 168          # 7-day summary
  hook-health.sh --recent     # Last 10 executions
  hook-health.sh --failures   # Recent failures only
  hook-health.sh --tail       # Follow log in real-time
  ```

- **`worktree-create-log.sh`** / **`worktree-remove-log.sh`**
  Emit `worktree_created` / `worktree_removed` via `dev-os-emit.sh` then run the real worktree add/remove. Intended to be used as the actual worktree add/remove command (e.g. from a wrapper or git hook) so experiments are logged.

- **`match-cues.sh`**
  Finds cues matching a subject (prompt, command, or file path). Supports:
  - Regex matching via `pattern:`, `commands:`, `files:` frontmatter
  - Scope filtering via `CUE_SCOPE_FILTER` env var (default: "agent")
  - Semantic matching via `description:` and `vocabulary:` fields
  ```bash
  match-cues.sh prompt "commit my changes"
  CUE_SCOPE_FILTER="subagent" match-cues.sh prompt "review code"
  ```

- **`show-cue.sh`**
  Outputs cue content with marker gating and macro support. Emits `cue_fired` event for engagement tracking.
  ```bash
  show-cue.sh /path/to/cue/dir [session_id] [trigger_type]
  ```
  - If `session_id` provided, checks/creates marker to prevent duplicates
  - If cue has `macro: prepend|append` and `macro.sh`, executes and combines output
  - Emits `cue_fired` event with `{cue_id, trigger_type, has_macro}` payload
  - Strips frontmatter, outputs body (and macro output)

- **`semantic-match.sh`**
  Gzip NCD (Normalized Compression Distance) similarity matching.
  ```bash
  semantic-match.sh "query text" "description text" "vocabulary words"
  ```
  - Returns 0 (match) if NCD < threshold (default 0.65)
  - First checks if any vocabulary word appears in query (fast path)
  - Falls back to gzip compression similarity for longer queries

## Input/output

- Hooks receive **JSON on stdin** (event payload from Claude Code; structure depends on the event).
- Exit **0**: success; **non-zero**: failure (for command hooks, may block or surface in the UI depending on the event).
- **task-gate.sh** exits **2** to block task completion when checks fail; it also emits `task_completed` on success.
- **hard-stop-test-blocker.sh** prints `{"ok":false,"reason":"..."}` to block stopping when the last `test_run` in `$HOME/.claude/dev-os-events.jsonl` is failed; otherwise `{"ok":true}`. It always exits 0.
- Scripts can print JSON to stdout to influence Claude (e.g. `async-test-runner.sh` and `large-diff-escalator.sh` print system messages; Stop command prints `ok`/`reason`).

Paths may be **project** (e.g. `.claude/` under `$CLAUDE_PROJECT_DIR`) or **home** (`$HOME/.claude/`); see “Context for each hook” below.

---

## Hook health monitoring

Hooks can opt into health monitoring by calling `hook_register` at startup. This provides “observability of the observer” - when hooks fail silently, you'll know.

**To instrument a hook:**
```bash
source “$SCRIPT_DIR/validate-path.sh”
hook_register “my-hook-name”   # Call early; sets up EXIT trap

INPUT=$(cat)
hook_set_context “$INPUT”      # Capture session/tool context for observability

# ... hook logic ...
# Exit trap automatically logs success/failure to ~/.claude/hook-health.jsonl
```

**What gets logged:**
- `timestamp`, `hook`, `status` (success/failure), `duration_ms`, `error`
- Extended context (when `hook_set_context` is called):
  - `session_id` - links execution to Claude session
  - `hook_event` - lifecycle event (PostToolUse, SessionStart, etc.)
  - `tool_name` - for tool-related hooks (Read, Write, Bash, etc.)

**How to check health:**
```bash
~/.claude/hooks/hook-health.sh           # 24h summary
~/.claude/hooks/hook-health.sh --recent  # Last 10 runs
~/.claude/hooks/hook-health.sh --tail    # Live follow
```

**SessionStart reporter:** The `hook-health-reporter.sh` hook runs at session start and surfaces a warning if hook failure rate exceeds 10% or there are more than 5 failures in the last 24 hours.

---

## Hook composition bus

Hooks within the same event invocation can share structured JSON findings via the hook bus. This avoids duplicated work when multiple hooks analyze the same tool call.

**How it works:** Each tool call gets a unique bus directory at `/tmp/.claude-hook-bus-<session>-<tool>-<hash>/`. Hooks write named JSON files; later hooks in the same matcher group read them. Directories auto-expire after 5 minutes.

**Producer pattern:**
```bash
source "$SCRIPT_DIR/validate-path.sh"
hook_register "my-hook"
hook_set_context "$INPUT"
hook_bus_init "$INPUT"

# ... analysis logic ...

hook_bus_put "my-hook" '{"found": true, "detail": "something"}'
```

**Consumer pattern:**
```bash
hook_bus_init "$INPUT"

if hook_bus_has "my-hook"; then
  result=$(hook_bus_get "my-hook")
  found=$(echo "$result" | jq -r '.found')
  # ... use the finding ...
fi
```

**Ordering requirement:** Hooks within the same `hooks` array run in **parallel**. For the bus to work reliably, producers and consumers must be in **separate matcher entries** (which run sequentially). In `hooks.jsonc`, the Bash PreToolUse hooks are split into two matcher groups: phase 1 (producers like `block-destructive`) and phase 2 (consumers like `exfiltration-check`).

**Current producers/consumers:**
- `block-destructive.sh` publishes → `exfiltration-check.sh` consumes (separate Bash matcher groups)
- `secret-scanner.sh` publishes (Write|Edit group, available to downstream hooks)

**Cleanup:** `session-end-tracker.sh` calls `hook_bus_cleanup` to remove expired bus directories.

---

## Project phase modes

Modes control hook/cue behavior intensity across the project lifecycle. The current mode is stored in a file and persists across sessions.

**Valid modes:**

| Mode | Guards | Cues | Use When |
|------|--------|------|----------|
| `exploration` | Lenient (skips several guards) | Fewer fire | Spiking, prototyping |
| `default` | Normal | Normal | Standard development |
| `hardening` | Strict (layering violations blocked) | More fire | Pre-merge stabilization |
| `release` | Strict + freeze | Release-focused | Cutting releases |

**Mode file:** `${CLAUDE_PROJECT_DIR}/.claude/project-mode` (project-specific) or `${CLAUDE_HOME}/project-mode` (global fallback).

**Switching modes:** Use the `/mode` skill (e.g., `/mode hardening`).

**Hook usage:**
```bash
source "$SCRIPT_DIR/validate-path.sh"

# Skip this hook in exploration mode
if is_mode "exploration"; then
  exit 0
fi

# Require hardening or release mode
require_mode "hardening" "release" || exit 0
```

**Cue usage:** Add `mode:` to cue frontmatter to restrict when a cue fires:
```yaml
---
pattern: test|spec
mode: default, hardening
---
```
Cues without a `mode:` field fire in all modes (backwards compatible).

**Mode-aware hooks:**
- `uncommitted-change-guard.sh` — skipped in `exploration`
- `hard-stop-test-blocker.sh` — skipped in `exploration`
- `ai-guardrails.sh` — skipped in `exploration`
- `layering-guard.sh` — skipped in `exploration`, hard-blocks in `hardening`/`release`

---

## Context for each hook

### SessionStart

- **session-context-injector.sh**  
  Runs on startup/resume (matcher: `startup|resume`). Reads from the **project** `.claude/`: last 5 lines of `impact-log.jsonl`, last 5 of `skill-friction-log.jsonl`, and the latest markdown in `decision-journal/`. Builds a short “Recent Impact / Recent Friction / Recent Decision Journal” summary and outputs it as `hookSpecificOutput.additionalContext` so Claude sees it at session start. If those files don’t exist or are in `$HOME/.claude/`, this may inject nothing.

- **friction-escalator.sh**
  Runs right after the context injector. Reads **`$HOME/.claude/skill-friction-log.jsonl`** (last 20 lines). If one domain (or `unknown`) appears 3+ times, it outputs `hookSpecificOutput.additionalContext` suggesting repeated friction in that domain and to consider deliberate study; optionally includes subdomain breakdown and a recent hint. Otherwise exits without output.

- **hook-health-reporter.sh**
  Runs after friction-escalator. Reads **`$HOME/.claude/hook-health.jsonl`** and computes 24-hour stats. If failure rate exceeds 10% or total failures exceed 5, outputs a warning via `hookSpecificOutput.additionalContext` listing the top failing hooks and their error messages. Provides "observability of the observer" - ensures you know when the telemetry system itself is failing.

- **branch-staleness-check.sh**
  Runs on startup/resume. Checks if the current branch is significantly behind the main branch (default threshold: 20 commits). Fetches origin with a 5-second timeout to get latest commit counts. Outputs a warning via `hookSpecificOutput.additionalContext` with rebase/merge suggestions if the branch is stale. Skips if: not in a git repo, on main/master branch, or in detached HEAD state. Emits `branch_stale` telemetry event with branch name, behind/ahead counts.

### UserPromptSubmit

- **idea-classifier.sh**  
  Runs on every user prompt. If the prompt matches heuristics (e.g. “annoying”, “frustrating”, “tradeoff”, “should we”, “I think … wrong”), it appends an entry to **`$HOME/.claude/idea-vault.md`** with timestamp, tags (#DX, #architecture, #AI-infra, #org-design, #career-strategy, or #unclassified), and the prompt text. Also emits a `prompt_opinion` event via `dev-os-emit.sh`. Does not block the prompt.

### PreToolUse

- **layering-guard.sh**
  Runs before **Write** or **Edit** (matcher: `Write|Edit`). Only considers paths under `app/`. Inspects the **content** being written and blocks (by outputting `permissionDecision: “ask”` and a reason) when it detects: (1) a file under `app/models` referencing “controller”, (2) a file under `app/services` referencing “render”/”view”/”erb”, or (3) a file under `app/models`, `app/domain`, or `app/services` referencing “aws”, “net/http”, “open3”, “system(“, “exec(“, “file.open”. Otherwise exits 0 and allows the tool.

- **git-guard.sh**
  Runs before **Bash** (matcher: `Bash`). Blocks dangerous commands (rm -rf /, mkfs, dd of=/dev, DROP DATABASE/TABLE, DELETE without WHERE) and enforces conventional commit format for `git commit` commands. Returns `{decision: “block”, reason: “...”}` to prevent execution, or `{decision: “approve”}` to allow.

- **block-destructive.sh**
  Runs before **Bash** (matcher: `Bash`). Defense-in-depth for destructive commands not covered by git-guard: git force operations (`push --force`, `reset --hard origin`, `checkout .`, `git restore .`, `git clean -fd`), pipe-to-shell attacks (`curl|bash`, `wget|sh`), and home/root directory wipes. Returns `{ok: false, error: “...”, suggestion: “...”}` to block with helpful alternatives. Emits `destructive_command_blocked` telemetry event. Uses `hook_register` for health monitoring.

- **exfiltration-check.sh**
  Runs before **Bash** (matcher: `Bash`). Detects potential data exfiltration patterns. **Hard deny rules** (always block): network transfer of sensitive files (.env, .pem, .key, etc.), piping secrets to network commands, command substitution of secrets in curl/wget, direct file transfer (scp/rsync) of sensitive files, posting env vars with SECRET/TOKEN/KEY to network. **Soft rules** (prompt for confirmation): base64/hex encoding piped to network, DNS exfiltration via command substitution, scripting language network calls with sensitive file references, script-write-then-execute patterns, tar/zip piped directly to network. Emits `exfiltration_blocked` or `exfiltration_warning` telemetry events. Uses `hook_register` for health monitoring.

- **uncommitted-change-guard.sh**
  Runs before **Write** or **Edit** (matcher: `Write|Edit`). Checks if the target file has uncommitted changes (staged or unstaged) in git. If changes exist, approves but includes a WARNING in the reason field alerting that changes will be overwritten, with suggestions to `git stash` or `git add` first. Prevents silent loss of in-progress work. Skips if: file doesn't exist (new file creation), not in a git repo, or file has no uncommitted changes. Emits `uncommitted_change_warning` telemetry event.

- **secret-scanner.sh**
  Runs before **Write** or **Edit** (matcher: `Write|Edit`). Scans content for secrets before writing to files. **Blocks** writes containing: AWS access keys/secrets, GitHub PATs (ghp_, gho_, ghs_, ghr_), private keys (RSA, EC, OpenSSH), Slack tokens/webhooks, Stripe keys (live and test), database connection strings with passwords, generic API key/password/secret assignments, Anthropic/OpenAI API keys, Google API keys, SendGrid/Twilio tokens, NPM access tokens. **Allows** `.env.example`, `.env.sample`, `.env.template` files (template files should have placeholders). Returns `{decision: "block", reason: "..."}` with list of detected secrets and remediation suggestions. Emits `secret_detected` telemetry event. Uses `hook_register` for health monitoring.

- **large-file-guard.sh**
  Runs before **Read** (matcher: `Read`). Implements ADR-0008 (Chunked Operation Pattern). Hard-blocks session logs (`~/.claude/projects/*.jsonl`) and very large files (>10MB). For large-but-readable files (>1000 lines or >256KB), outputs advisory warnings with chunked reading recommendations. Uses `size_estimate()` from validate-path.sh for pre-flight analysis.

- **bulk-operation-estimator.sh**
  Runs before **Glob** or **Grep** (matcher: `Glob|Grep`). Estimates the scope of bulk file operations and warns if the pattern might match an excessive number of files.

- **principle-reinforcer.sh**
  Runs before **Write** or **Edit** (matcher: `Write|Edit`). Reinforces engineering principles based on the type of file being edited.

- **agent-spawn-tracker.sh**
  Runs before **Agent** (matcher: `Agent`). Tracks agent spawns for observability and warns on potential coordination issues. Logs each spawn to a session-scoped state file (`/tmp/claude-agent-spawns.json`) with: subagent_type, description, run_in_background, isolation mode, model override, and spawn count. **Warnings**: >10 agents spawned in session (consider consolidation), >3 background agents active (coordination risk), worktree isolation in use (informational). Emits `agent_spawn` telemetry event with full spawn metadata. Uses `hook_register` for health monitoring.

### PostToolUse (Write|Edit only, in order)

- **impact-extractor.sh**  
  Runs only for Write/Edit in a git repo. Reads the diff of the edited file, classifies **change_type** (refactor, architecture, bugfix, test, infra) and **risk_level**, guesses **skill_domains** from path (e.g. compiler design, domain modeling, developer tooling). Appends one line to **`$HOME/.claude/impact-log.jsonl`** with timestamp, file, change_type, skill_domains, impact_guess, risk_level. Also emits `tool_write` to `dev-os-events.jsonl` via `dev-os-emit.sh`.

- **large-diff-escalator.sh**  
  Only runs in a git repo. Uses `git diff --shortstat` for the edited file. If **lines changed > 250**, emits `large_change` to dev-os-events (payload: file_path, lines_changed, risk:"high") and prints a **systemMessage** asking to summarize risk surface before continuing. No-op otherwise.

- **dependency-change-detector.sh**  
  Only runs when the edited file is one of: `Gemfile`, `package.json`, `Cargo.toml`, `requirements.txt`. Computes lines added/removed in the diff and emits `dependency_change` to dev-os-events (file_path, lines_added, lines_removed). Does not block or inject a message.

- **reversal-detector.sh**  
  Only runs in a git repo. Counts added vs removed lines in the edited file. If **removed > 50** and **removed > added**, emits `reversal` to dev-os-events with `likely_cause: "exploration_reversal"`. Useful to spot large rollbacks or exploration being reverted.

- **async-test-runner.sh**
  Runs **async** (does not block). Only runs when the edited file has extension `.rb`, `.ts`, or `.js`. Runs `bundle exec rspec` (Ruby); result is emitted as `test_run` (payload: `result: “passed”` or `”failed”`). If tests failed, prints a **systemMessage**: “Tests failed after last edit.”

- **ai-guardrails.sh**
  Detects common AI-assisted development pitfalls. Non-blocking hook that outputs guidance via `additionalContext`:
  - **Untested code**: Warns when new JS/TS/Ruby source files have no corresponding test file. Auto-detects test framework (rspec vs minitest for Ruby; checks for spec/ or test/ directories and Gemfile).
  - **Generic placeholders**: Flags files with 2+ placeholders (TODO, FIXME, example.com, REPLACE_ME, NotImplementedError).
  - **Hallucinated dependencies**: Warns when package.json, Gemfile, or Cargo.toml is written to verify packages exist.
  - **Large files**: Warns when files >300 lines are written with minimal structure.
  - **Ruby-specific**: Suggests `frozen_string_literal` magic comment for new Ruby files. Detects test framework (rspec/minitest) and linter (rubocop/standardrb) automatically.
  Emits `ai_guardrails_triggered` telemetry event with warning count.

### PostToolUseFailure

- **skill-gap-detector.sh**  
  Runs after a tool failure (matcher includes Bash, Task, Read, Write, Edit, Glob, Grep, MCP). Skips if both error and command are empty. Classifies the failure into a **friction taxonomy**: domain (syntax, type, dependency, permission, network, state, config, testing, build) and subdomain (e.g. file-not-found, json-parse, typescript, bundler), and collects **hints** (short remediation suggestions). Appends one JSON object per line to **`$HOME/.claude/skill-friction-log.jsonl`** (timestamp, tool_name, file_paths, domain, subdomain, error_excerpt, hints, signals). Also emits `tool_failure` to dev-os-events with tool and friction_domain. This log is what **friction-escalator** and **learning-suggestion-generator** read.

### Stop

- **hard-stop-test-blocker.sh**
  Runs first in the Stop sequence. Reads **`$HOME/.claude/dev-os-events.jsonl`** and finds the most recent `test_run` event. If that event’s `payload.result` is `"failed"`, prints `{"ok":false,"reason":"Cannot stop: last test_run event failed. Fix tests before stopping."}` so the UI blocks stop; otherwise prints `{"ok":true}`. If the file doesn’t exist, allows stop. Always exits 0.

- **leverage-evaluator.sh**
  Runs in the Stop sequence. Evaluates whether the session produced meaningful leverage by checking for indicators like files written, decisions documented, or tests run. Returns `{"ok":true}` to allow stopping if value was produced.

- **cost-tracker.sh**
  Runs at the end of the Stop sequence. Tracks token costs per model per session. Extracts `input_tokens`, `output_tokens`, `cache_read_input_tokens`, and `cache_creation_input_tokens` from the Stop event payload. Calculates estimated cost using current pricing (Haiku 4.5: $1/$5, Sonnet 4.x: $3/$15, Opus 4.5/4.6: $5/$25, Opus 4/4.1: $15/$75 per MTok). Writes JSONL entries to **`$HOME/.claude/metrics/costs.jsonl`** with timestamp, session_id, model, token counts, and estimated_cost_usd. Emits `cost_tracked` telemetry event. Uses `hook_register` for health monitoring.

### TaskCompleted

- **task-gate.sh**  
  Runs when a task is marked complete. **Blocks completion** (exit 2 and message to stderr) if: (1) `bundle exec rspec` fails (when Gemfile exists), (2) `bundle exec rubocop` fails when rubocop is available, (3) `db/migrate` exists but no migration has `def change`, or (4) staged diff adds “public def” but no `@doc`/comment is found in `app/`. On success, emits `task_completed` (payload: `status: "passed"`) via `dev-os-emit.sh` and exits 0.

### PreCompact

- **pre-compact-snapshot.sh**  
  Runs before context compaction. Reads the **transcript_path** from hook stdin and takes the last 50 lines of that transcript. Writes a markdown file to **`$HOME/.claude/session-summaries/<TIMESTAMP>.md`** with a template (Key Decisions, New Abstractions, Unresolved Questions) and a “Raw Transcript Tail” section containing those 50 lines. Lets you preserve a snapshot before the context window is compacted.

### SessionEnd

- **learning-suggestion-generator.sh**  
  Runs when the session ends. Reads **`$HOME/.claude/impact-log.jsonl`** and **`$HOME/.claude/skill-friction-log.jsonl`** (counts last 30 entries) and **`$HOME/.claude/decision-journal/`** (`.md` files, last 200 lines each). Produces **`$HOME/.claude/learning-targets/latest.md`** with: generated time, impact/friction counts; “Where you’re bleeding” (top friction domains); “Where you’re investing” (top skill domains from impact); “Principles showing up in your decisions” (keywords from journal); and “Next 3 precision moves” (deliberate practice, reading, and writing suggestions). Designed for weekly review or follow-up learning.
