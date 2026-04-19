---
status: accepted
date: 2026-04-19
deciders: [meaganewaller]
---

# 4. JSONC merge strategy for Claude Code settings

## Status

Accepted

## Context

Claude Code reads a single `~/.claude/settings.json` file. This dotfiles repository needs to:

- **Share common settings** (hooks, permissions, base preferences) across all profiles
- **Override per profile** (work adds Gusto env vars and a different status line; personal has its own status line)
- **Preserve internal state** that Claude Code writes to `settings.json` at runtime (e.g., `numStartups`, `userID`, `projects`)
- **Use JSONC** (JSON with comments) in source files for readability, even though Claude Code reads plain JSON

A single checked-in `settings.json` would force choosing one profile's config, and Claude Code's runtime writes would create constant merge conflicts.

## Decision

1. **Source files are JSONC** — stored in `home/.claude/settings/common/` and `home/.claude/settings/<profile>/`, split by concern (e.g., `base.jsonc`, `hooks.jsonc`, `permissions/*.jsonc`).

2. **Merge at install time** — `home/.claude/install.sh` runs `merge_config()` which:
   - Discovers all `.jsonc`/`.json` files under `common/` then `<profile>/` using `fd`, sorted deterministically
   - Parses JSONC to JSON using `npx -y -p json5 node` (single Node process for all files)
   - Deep-merges with `jq`, profile values overriding common values
   - **Permissions are union-merged**: `allow`, `deny`, and `additionalDirectories` arrays are concatenated and deduplicated across all layers
   - All other keys use last-writer-wins (profile overrides common)

3. **Internal state preservation** — before merging, the existing `settings.json` is read and Claude Code's internal fields (`numStartups`, `userID`, `projects`, etc.) are extracted. These are merged back in after the dotfiles layers, so they survive re-linking.

4. **Profile directories may be empty stubs** — server and container profiles have minimal `basics.jsonc` files so the merge has a directory to scan without errors.

## Alternatives considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Single `settings.json` per profile** | Duplicates shared config (hooks, permissions); changes must be applied to every copy |
| **JSON (no comments)** | Settings files benefit from inline documentation explaining why a permission or hook exists |
| **Template rendering (ERB, envsubst)** | Adds complexity; JSONC + jq merge is sufficient for key-value overrides |
| **Claude Code's native config** | Claude Code doesn't support config layering or profile merging natively |

## Consequences

**Positive**

- Single source of truth for each setting — common settings are defined once
- Profile overrides are explicit and auditable (separate files, not environment variable interpolation)
- Internal state survives re-linking without manual intervention

**Negative**

- **Depends on Node.js and jq** — both must be available at install time (checked with actionable error messages per [ADR context])
- **npx network dependency** — first run fetches `json5` package; fails without network access (mitigated by checking for npx and providing fallback guidance)
- Merge order matters — profile files override common files, but within a layer, files are sorted alphabetically

**Neutral**

- Adding a new settings concern means creating a new `.jsonc` file in the appropriate directory; no wiring needed beyond the file existing
