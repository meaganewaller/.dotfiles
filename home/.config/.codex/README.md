# Codex Configuration

Codex configuration managed by dotfiles using an explicit allowlist.
Managed files are linked into `~/.codex` (source files remain in this repo under `home/.config/.codex`).

## Managed by dotfiles

- `config.toml`
- `AGENTS.md` (optional)
- `devos/**` (repo-owned DevOS docs/skills/cues/governance assets)
- `~/.local/bin/codex-tradeoff` (via dotfiles linker)
- `~/.local/bin/codex-tradeoff-gate` (pre-commit integration)
- `~/.local/bin/codex-weekly-review` (weekly review artifact generator)
- `~/.local/bin/codex-governance` (provenance governance CLI)

## Unmanaged (never symlinked)

- Authentication/session/runtime state (for example `auth.json`)
- Caches and Codex-generated local state files

## Commands

```bash
# Sync managed Codex config
mise run codex

# Preview without changing files
mise run codex:dry-run

# Capture a Codex tradeoff decision
codex-tradeoff "Chose X over Y because Z"

# Generate weekly review artifacts
codex-weekly-review  # profile default (work=claude, personal=codex)
codex-weekly-review --mode combined
codex-weekly-review --mode codex
codex-weekly-review --mode claude

# Governance checks
dotfiles codex-governance
dotfiles codex-governance --lint
```
