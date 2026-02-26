# Claude Code hooks

This directory holds **hook scripts** that run in response to Claude Code events. Hooks are wired in `settings/common/hooks.jsonc`; when you run `mise run claude`, those settings determine which scripts run and for which tools/events.

## Layout

```
hooks/
├── README.md                  # this file
└── common/                   # shared hooks (used by all profiles)
    ├── validate-path.sh      # shared utilities: path validation, health monitoring
    ├── dev-os-emit.sh        # helper: append events to .claude/dev-os-events.jsonl
    ├── hook-health.sh        # CLI: check hook execution health
    ├── worktree-create-log.sh # log worktree creation (e.g. from git hook or script)
    ├── worktree-remove-log.sh # log worktree removal
    ├── SessionStart/
    │   ├── session-context-injector.sh
    │   ├── friction-escalator.sh
    │   └── hook-health-reporter.sh
    ├── UserPromptSubmit/
    │   └── idea-classifier.sh
    ├── PreToolUse/
    │   └── layering-guard.sh
    ├── PostToolUse/
    │   ├── impact-extractor.sh
    │   ├── large-diff-escalator.sh
    │   ├── dependency-change-detector.sh
    │   ├── reversal-detector.sh
    │   ├── tradeoff-capture.sh
    │   └── async-test-runner.sh
    ├── PostToolUseFailure/
    │   └── skill-gap-detector.sh
    ├── Stop/
    │   ├── hard-stop-test-blocker.sh
    │   └── pending-tradeoff-blocker.sh
    ├── TaskCompleted/
    │   └── task-gate.sh
    ├── PreCompact/
    │   └── pre-compact-snapshot.sh
    └── SessionEnd/
        └── learning-suggestion-generator.sh
```

Event names match Claude Code’s hook events; scripts under each folder are invoked when that event fires (and when the optional **matcher** in `hooks.jsonc` matches, e.g. `Write|Edit`).

## How hooks are wired

- **Where**: `home/.claude/settings/common/hooks.jsonc` defines `hooks` with event names as keys.
- **Commands**: Each entry can run a `command` (script path), a `prompt`, or an `agent`. Script paths use `$CLAUDE_PROJECT_DIR` (project root).
- **Matchers**: Optional `matcher` limits the hook to certain tools or triggers (e.g. only after `Write` or `Edit`).
- **Order**: Scripts under the same event run in the order listed; `async: true` runs that script without blocking.

**Stop** runs a command first (`hard-stop-test-blocker.sh`), then a prompt gate. **SubagentStop** is defined entirely in the JSON (agent only).

**Paths:** Some hooks use the **project** `.claude/` (e.g. `session-context-injector` reads from the repo’s `.claude/`). Others use **`$HOME/.claude/`** for logs and outputs (e.g. `impact-log.jsonl`, `skill-friction-log.jsonl`, `dev-os-events.jsonl`, `learning-targets/`). Scripts in this repo may use either depending on whether the data is project-specific or global.

## Event → script summary

| Event              | Script(s) | When / purpose |
|--------------------|-----------|----------------|
| **SessionStart**   | `session-context-injector.sh`, `friction-escalator.sh`, `hook-health-reporter.sh` | On startup/resume: inject recent impact, friction, and decision-journal context; if recent friction log shows 3+ hits in one domain, inject a suggestion to study that domain; report hook health issues if failure rate >10%. |
| **UserPromptSubmit** | `idea-classifier.sh` | On every prompt: if the prompt looks like a strong opinion or tradeoff, append to `.claude/idea-vault.md`. |
| **PreToolUse**     | `layering-guard.sh` | Before Write/Edit: block app code that violates layering (e.g. models referencing controllers). |
| **PostToolUse**    | `impact-extractor.sh`, `large-diff-escalator.sh`, `dependency-change-detector.sh`, `reversal-detector.sh`, `async-test-runner.sh` | After Write/Edit: log change type to impact log; if diff >250 lines emit `large_change` and prompt to summarize risk; if dependency file changed emit `dependency_change`; if large net removal (reversal) emit `reversal`; run tests and emit `test_run` (async). |
| **PostToolUseFailure** | `skill-gap-detector.sh` | After tool failure: classify and append to `.claude/skill-friction-log.jsonl`. |
| **Stop**           | `hard-stop-test-blocker.sh` (then prompt) | Before allowing stop: block if last `test_run` in dev-os-events was failed; then prompt gate for meaningful leverage. |
| **TaskCompleted**  | `task-gate.sh` | When a task is marked complete: run rspec, rubocop, migration/reversible and public-API-doc checks; on success emit `task_completed`. |
| **PreCompact**     | `pre-compact-snapshot.sh` | Before context compact: write a snapshot to `.claude/session-summaries/`. |
| **SessionEnd**     | `learning-suggestion-generator.sh` | On session end: generate `.claude/learning-targets/latest.md` from impact/friction/journal. |

## Helper scripts

- **`validate-path.sh`**
  Shared utility library sourced by most hooks. Provides:
  - Path constants: `CLAUDE_HOME`, `CLAUDE_EVENTS_LOG`, `CLAUDE_FRICTION_LOG`, `CLAUDE_IMPACT_LOG`, `CLAUDE_HOOK_HEALTH_LOG`
  - Validation functions: `validate_file_exists`, `validate_file_readable`, `validate_dir_exists`
  - Ensure functions: `ensure_dir_exists`, `ensure_file_exists`
  - Safe I/O: `safe_tail`, `safe_append`, `safe_emit`
  - Resource guards: `guard_diff_size`, `guard_file_size`, `guard_log_size`
  - **Hook health monitoring**: `hook_register`, `hook_success`, `hook_failure`, `hook_health_summary`

- **`dev-os-emit.sh`**
  Used by other hooks to append a single JSON line to `.claude/dev-os-events.jsonl`.
  Usage: `echo '<hook stdin>' | ./dev-os-emit.sh <event_type> '<payload json>'`.
  Event types used: `test_run`, `task_completed`, `worktree_created`, `worktree_removed`, `large_change`, `dependency_change`, `reversal`, `tool_write`, `tool_failure`, `prompt_opinion`. Subagent **SubagentStop** can also write `decision_tradeoff` events to the same file (via the agent, not this script). Output is written to **`$HOME/.claude/dev-os-events.jsonl`**.

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
# ... hook logic ...
# Exit trap automatically logs success/failure to ~/.claude/hook-health.jsonl
```

**What gets logged:**
- Timestamp, hook name, status (success/failure), duration in ms, error message (if any)

**How to check health:**
```bash
~/.claude/hooks/hook-health.sh           # 24h summary
~/.claude/hooks/hook-health.sh --recent  # Last 10 runs
~/.claude/hooks/hook-health.sh --tail    # Live follow
```

**SessionStart reporter:** The `hook-health-reporter.sh` hook runs at session start and surfaces a warning if hook failure rate exceeds 10% or there are more than 5 failures in the last 24 hours.

---

## Context for each hook

### SessionStart

- **session-context-injector.sh**  
  Runs on startup/resume (matcher: `startup|resume`). Reads from the **project** `.claude/`: last 5 lines of `impact-log.jsonl`, last 5 of `skill-friction-log.jsonl`, and the latest markdown in `decision-journal/`. Builds a short “Recent Impact / Recent Friction / Recent Decision Journal” summary and outputs it as `hookSpecificOutput.additionalContext` so Claude sees it at session start. If those files don’t exist or are in `$HOME/.claude/`, this may inject nothing.

- **friction-escalator.sh**
  Runs right after the context injector. Reads **`$HOME/.claude/skill-friction-log.jsonl`** (last 20 lines). If one domain (or `unknown`) appears 3+ times, it outputs `hookSpecificOutput.additionalContext` suggesting repeated friction in that domain and to consider deliberate study; optionally includes subdomain breakdown and a recent hint. Otherwise exits without output.

- **hook-health-reporter.sh**
  Runs after friction-escalator. Reads **`$HOME/.claude/hook-health.jsonl`** and computes 24-hour stats. If failure rate exceeds 10% or total failures exceed 5, outputs a warning via `hookSpecificOutput.additionalContext` listing the top failing hooks and their error messages. Provides "observability of the observer" - ensures you know when the telemetry system itself is failing.

### UserPromptSubmit

- **idea-classifier.sh**  
  Runs on every user prompt. If the prompt matches heuristics (e.g. “annoying”, “frustrating”, “tradeoff”, “should we”, “I think … wrong”), it appends an entry to **`$HOME/.claude/idea-vault.md`** with timestamp, tags (#DX, #architecture, #AI-infra, #org-design, #career-strategy, or #unclassified), and the prompt text. Also emits a `prompt_opinion` event via `dev-os-emit.sh`. Does not block the prompt.

### PreToolUse

- **layering-guard.sh**  
  Runs before **Write** or **Edit** (matcher: `Write|Edit`). Only considers paths under `app/`. Inspects the **content** being written and blocks (by outputting `permissionDecision: "ask"` and a reason) when it detects: (1) a file under `app/models` referencing “controller”, (2) a file under `app/services` referencing “render”/“view”/“erb”, or (3) a file under `app/models`, `app/domain`, or `app/services` referencing “aws”, “net/http”, “open3”, “system(”, “exec(”, “file.open”. Otherwise exits 0 and allows the tool.

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
  Runs **async** (does not block). Only runs when the edited file has extension `.rb`, `.ts`, or `.js`. Runs `bundle exec rspec` (Ruby); result is emitted as `test_run` (payload: `result: "passed"` or `"failed"`). If tests failed, prints a **systemMessage**: “Tests failed after last edit.”

### PostToolUseFailure

- **skill-gap-detector.sh**  
  Runs after a tool failure (matcher includes Bash, Task, Read, Write, Edit, Glob, Grep, MCP). Skips if both error and command are empty. Classifies the failure into a **friction taxonomy**: domain (syntax, type, dependency, permission, network, state, config, testing, build) and subdomain (e.g. file-not-found, json-parse, typescript, bundler), and collects **hints** (short remediation suggestions). Appends one JSON object per line to **`$HOME/.claude/skill-friction-log.jsonl`** (timestamp, tool_name, file_paths, domain, subdomain, error_excerpt, hints, signals). Also emits `tool_failure` to dev-os-events with tool and friction_domain. This log is what **friction-escalator** and **learning-suggestion-generator** read.

### Stop

- **hard-stop-test-blocker.sh**  
  Runs first in the Stop sequence (before the leverage prompt). Reads **`$HOME/.claude/dev-os-events.jsonl`** and finds the most recent `test_run` event. If that event’s `payload.result` is `"failed"`, prints `{"ok":false,"reason":"Cannot stop: last test_run event failed. Fix tests before stopping."}` so the UI blocks stop; otherwise prints `{"ok":true}`. If the file doesn’t exist, allows stop. Always exits 0.

### TaskCompleted

- **task-gate.sh**  
  Runs when a task is marked complete. **Blocks completion** (exit 2 and message to stderr) if: (1) `bundle exec rspec` fails (when Gemfile exists), (2) `bundle exec rubocop` fails when rubocop is available, (3) `db/migrate` exists but no migration has `def change`, or (4) staged diff adds “public def” but no `@doc`/comment is found in `app/`. On success, emits `task_completed` (payload: `status: "passed"`) via `dev-os-emit.sh` and exits 0.

### PreCompact

- **pre-compact-snapshot.sh**  
  Runs before context compaction. Reads the **transcript_path** from hook stdin and takes the last 50 lines of that transcript. Writes a markdown file to **`$HOME/.claude/session-summaries/<TIMESTAMP>.md`** with a template (Key Decisions, New Abstractions, Unresolved Questions) and a “Raw Transcript Tail” section containing those 50 lines. Lets you preserve a snapshot before the context window is compacted.

### SessionEnd

- **learning-suggestion-generator.sh**  
  Runs when the session ends. Reads **`$HOME/.claude/impact-log.jsonl`** and **`$HOME/.claude/skill-friction-log.jsonl`** (counts last 30 entries) and **`$HOME/.claude/decision-journal/`** (`.md` files, last 200 lines each). Produces **`$HOME/.claude/learning-targets/latest.md`** with: generated time, impact/friction counts; “Where you’re bleeding” (top friction domains); “Where you’re investing” (top skill domains from impact); “Principles showing up in your decisions” (keywords from journal); and “Next 3 precision moves” (deliberate practice, reading, and writing suggestions). Designed for weekly review or follow-up learning.
