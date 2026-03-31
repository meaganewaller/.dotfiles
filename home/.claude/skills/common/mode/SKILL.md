# Project Phase Mode

This skill should be used when the user asks to "set mode", "change mode", "switch to exploration", "switch to hardening", "what mode", "current mode", or "/mode". Manages the project phase mode which controls hook and cue strictness.

## Trigger Phrases
- "mode"
- "set mode"
- "change mode"
- "switch to exploration"
- "switch to hardening"
- "switch to release"
- "what mode"
- "current mode"

## How to Use

### View current mode

Run:
```bash
source "$HOME/.claude/hooks/validate-path.sh" && get_project_mode
```

### Set mode

To change mode, use the `set_project_mode` function:

```bash
source "$HOME/.claude/hooks/validate-path.sh" && set_project_mode "<MODE>"
```

Where `<MODE>` is one of:

| Mode | Guards | Cues | Use When |
|------|--------|------|----------|
| **exploration** | Lenient: skips uncommitted-change-guard, test-blocker, ai-guardrails, layering-guard | Fewer fire (mode-tagged cues filtered out) | Spiking, prototyping, exploring unfamiliar code |
| **default** | Normal | Normal | Standard development work |
| **hardening** | Strict: layering violations are blocked (not just warned) | More fire | Pre-merge stabilization, bug fixing |
| **release** | Strict + layering blocked | Release-focused cues | Cutting a release branch |

### After setting mode

Report the new mode to the user and briefly explain what changed.

### Resetting mode

To go back to normal:
```bash
source "$HOME/.claude/hooks/validate-path.sh" && set_project_mode "default"
```

## Mode Storage

Mode is stored in `${CLAUDE_PROJECT_DIR}/.claude/project-mode` (project-specific) or `${CLAUDE_HOME}/project-mode` (global fallback). It persists across sessions.

## Examples

User: `/mode`
Response: "Current project mode: **default**"

User: `/mode exploration`
Response: "Switched to **exploration** mode. Guards relaxed — uncommitted change warnings, test blockers, AI guardrails, and layering checks are disabled. Good for prototyping."

User: `/mode hardening`
Response: "Switched to **hardening** mode. Guards tightened — layering violations will be blocked outright. More quality cues will fire."
