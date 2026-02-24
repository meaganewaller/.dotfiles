# Claude Code hooks

This directory holds **hook scripts** that run in response to Claude Code events. Hooks are wired in `settings/common/hooks.jsonc`; when you run `mise run claude`, those settings determine which scripts run and for which tools/events.

## Layout

```
hooks/
├── README.md                  # this file
└── common/                   # shared hooks (used by all profiles)
    ├── dev-os-emit.sh        # helper: append events to .claude/dev-os-events.jsonl
    ├── worktree-create-log.sh # log worktree creation (e.g. from git hook or script)
    ├── worktree-remove-log.sh # log worktree removal
    ├── SessionStart/
    │   ├── session-context-injector.sh
    │   └── friction-escalator.sh
    ├── UserPromptSubmit/
    │   └── idea-classifier.sh
    ├── PreToolUse/
    │   └── layering-guard.sh
    ├── PostToolUse/
    │   ├── impact-extractor.sh
    │   ├── large-diff-escalator.sh
    │   ├── dependency-change-detector.sh
    │   ├── reversal-detector.sh
    │   └── async-test-runner.sh
    ├── PostToolUseFailure/
    │   └── skill-gap-detector.sh
    ├── Stop/
    │   └── hard-stop-test-blocker.sh
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

## Event → script summary

| Event              | Script(s) | When / purpose |
|--------------------|-----------|----------------|
| **SessionStart**   | `session-context-injector.sh`, `friction-escalator.sh` | On startup/resume: inject recent impact, friction, and decision-journal context; if recent friction log shows 3+ hits in one domain, inject a suggestion to study that domain. |
| **UserPromptSubmit** | `idea-classifier.sh` | On every prompt: if the prompt looks like a strong opinion or tradeoff, append to `.claude/idea-vault.md`. |
| **PreToolUse**     | `layering-guard.sh` | Before Write/Edit: block app code that violates layering (e.g. models referencing controllers). |
| **PostToolUse**    | `impact-extractor.sh`, `large-diff-escalator.sh`, `dependency-change-detector.sh`, `reversal-detector.sh`, `async-test-runner.sh` | After Write/Edit: log change type to impact log; if diff >250 lines emit `large_change` and prompt to summarize risk; if dependency file changed emit `dependency_change`; if large net removal (reversal) emit `reversal`; run tests and emit `test_run` (async). |
| **PostToolUseFailure** | `skill-gap-detector.sh` | After tool failure: classify and append to `.claude/skill-friction-log.jsonl`. |
| **Stop**           | `hard-stop-test-blocker.sh` (then prompt) | Before allowing stop: block if last `test_run` in dev-os-events was failed; then prompt gate for meaningful leverage. |
| **TaskCompleted**  | `task-gate.sh` | When a task is marked complete: run rspec, rubocop, migration/reversible and public-API-doc checks; on success emit `task_completed`. |
| **PreCompact**     | `pre-compact-snapshot.sh` | Before context compact: write a snapshot to `.claude/session-summaries/`. |
| **SessionEnd**     | `learning-suggestion-generator.sh` | On session end: generate `.claude/learning-targets/latest.md` from impact/friction/journal. |

## Helper scripts

- **`dev-os-emit.sh`**  
  Used by other hooks to append a single JSON line to `.claude/dev-os-events.jsonl`.  
  Usage: `echo '<hook stdin>' | ./dev-os-emit.sh <event_type> '<payload json>'`.  
  Event types used: `test_run`, `task_completed`, `worktree_created`, `worktree_removed`, `large_change`, `dependency_change`, `reversal`. Subagent **SubagentStop** can also write `decision_tradeoff` events to the same file (via the agent, not this script).

- **`worktree-create-log.sh`** / **`worktree-remove-log.sh`**  
  Emit `worktree_created` / `worktree_removed` via `dev-os-emit.sh` then run the real worktree add/remove. Intended to be used as the actual worktree add/remove command (e.g. from a wrapper or git hook) so experiments are logged.

## Input/output

- Hooks receive **JSON on stdin** (event payload from Claude Code; structure depends on the event).
- Exit **0**: success; **non-zero**: failure (for command hooks, may block or surface in the UI depending on the event).
- **task-gate.sh** exits **2** to block task completion when checks fail; it also emits `task_completed` on success.
- **hard-stop-test-blocker.sh** exits **2** to block stopping when the last `test_run` event in `.claude/dev-os-events.jsonl` is failed.
- Scripts can print JSON to stdout to influence Claude (e.g. `async-test-runner.sh` and `large-diff-escalator.sh` print system messages).

All paths in the table above are relative to the **project directory** (`$CLAUDE_PROJECT_DIR`), e.g. `.claude/impact-log.jsonl`, `.claude/decision-journal/`.
