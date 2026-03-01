# Codex Configuration

Codex configuration managed by dotfiles using an explicit allowlist.

## Managed by dotfiles

- `config.toml`
- `AGENTS.md` (optional)
- `devos/**` (repo-owned DevOS docs/skills/cues/governance assets)

## Unmanaged (never symlinked)

- Authentication/session/runtime state (for example `auth.json`)
- Caches and Codex-generated local state files

## Commands

```bash
# Sync managed Codex config
mise run codex

# Preview without changing files
mise run codex:dry-run
```
