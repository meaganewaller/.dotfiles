# Common profile

Settings in **common** are applied to every Claude Code session, regardless of which profile (personal/work) is active. Use this for shared defaults, hooks, and permissions.

## Files

### `basics.jsonc`

- **Model**: `opus` (overridable by profile).
- **Always thinking**: enabled.
- **Statusline**: `ccstatusline` (command type). Profiles can override with a custom script or powerline.
- **Env**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` for agent teams.

### `hooks.jsonc`

Event-driven hooks (run scripts or prompts at specific points in a session). All paths are under `$CLAUDE_PROJECT_DIR/.claude/hooks/`:

| Event              | Purpose |
|--------------------|---------|
| **SessionStart**   | Injects session context on startup/resume. |
| **UserPromptSubmit** | Classifies user ideas before handling. |
| **PreToolUse**     | Before Write/Edit: runs layering guard. |
| **PostToolUse**    | After Write/Edit: impact extractor + async test runner. |
| **PostToolUseFailure** | After tool failure: skill-gap detector. |
| **TaskCompleted**  | Task gate (e.g. completion checks). |
| **SubagentStop**   | Extracts architectural reasoning from Explore/Plan subagents into `.claude/dev-os-events.jsonl`. |
| **PreCompact**     | Snapshot before context compact. |
| **SessionEnd**     | Learning-suggestion generator. |
| **Stop**           | Prompt gate: only allow stop if session had meaningful leverage (abstraction, decision, improvement, or lesson). |

Matchers (e.g. `Write|Edit`) limit which tools trigger the hook.

### `plugins.jsonc`

Plugin enable/disable. Common currently has no plugins enabled; work profile adds Gusto plugins.

### `permissions/`

- **read.jsonc** – Allow read of `~/.zshrc`; deny `~/.ssh/**` and `.env`.
- **write.jsonc** – Allow write under `/tmp/**`, `~/.agents/**`, `~/.claude/**`, `~/.claude-prompts/**`.
- **bash.jsonc** – Allowlist of shell commands (git, node, python, ruff, etc.) and denylist (e.g. `sudo`, `rm -rf ~`, `git reset --hard`).
- **tools.jsonc** – Built-in tools: Glob, TodoWrite, WebFetch, WebSearch.
- **skills.jsonc** – Skill permissions (currently allow list empty).
- **additional-dirs.jsonc** – Extra readable directories: `/tmp`, `/var`, `~/.agents`, `~/.claude`, `~/.codex`.

To allow reading more directories, add them in `additional-dirs.jsonc`; for specific file read rules, use `read.jsonc`.
