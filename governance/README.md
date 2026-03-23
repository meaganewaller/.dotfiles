# Dotfiles governance

Policies and controls for **this repository** as a whole (machine setup, tools, shell layout). This is separate from **Claude Code** governance under `home/.claude/governance/`, which focuses on cue provenance, hooks, and agent policy traceability.

## Layout

| Path | Role |
|------|------|
| **`governance/policies/`** | Human-readable policies for dotfiles-wide concerns (e.g. [tool-management](policies/tool-management.md)) |
| **`governance/controls/`** | Control mappings for this layer (e.g. `custom-controls.yaml`) |
| **`governance/bin/`** | Legacy or shared scripts (see below) |
| **`home/.claude/governance/`** | Claude-specific policies, provenance scanning for **cues**, and the primary `governance.sh` entrypoint |

## CLI

```bash
dotfiles governance
```

Runs `home/.claude/governance/bin/governance.sh` (cue coverage, provenance, `--policy` traces for **Claude** policy URIs). Dotfiles-wide policies such as [tool-management](policies/tool-management.md) are authoritative documents in this directory; wire them into the scanner only if you add cue provenance pointing at `governance/policies/…`.

## Where to add what

- **Tooling, bootstrap, Brew vs mise, profiles** → `governance/policies/` here (and [docs/architecture/](../docs/architecture/) ADRs).
- **Agent behavior, secrets in prompts, commit hooks for Claude** → `home/.claude/governance/policies/`.

Older copies of some policies may exist under both trees for compatibility; prefer **one** canonical home for new edits (this directory for repo-wide, Claude tree for agent/cue policy).
