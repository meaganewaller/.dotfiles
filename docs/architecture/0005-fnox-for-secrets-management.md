---
status: accepted
date: 2026-05-03
deciders: [meaganewaller]
---

# 5. fnox for secrets management

## Status

Accepted

## Context

Secrets in this repo come in two flavors and are managed by two homegrown mise tasks:

1. **Runtime env vars** (e.g. `MISE_GITHUB_TOKEN`, `WAKATIME_API_KEY`) declared in `vars/runtime-secrets.toml`, fetched by `mise/tasks/secrets`, written to `~/.config/dotfiles/secrets.{env,fish}`, and sourced from `.zshrc` / `.bashrc`.

2. **Template values** (e.g. `secrets.git.work.email` for `.gitconfig` rendering) declared in `vars/secrets.toml`, fetched by `mise/tasks/secrets-templates`, written to `~/.config/dotfiles/secrets.json`, and merged into the Tera context by `mise/tasks/_render-context`.

Both paths call `op item get` directly, gated on `op whoami`. That has produced consistent friction:

- **Per-shell auth.** `op signin` only seeds an `OP_SESSION_*` token in the shell that ran it; new shells (or background invocations like child mise tasks) hit "Not signed into 1Password" and abort. We can't rely on the daemon-side session being available everywhere.
- **Two manifests for one concern.** Template values and env vars share a source of truth (1Password) and a fetch mechanism but have parallel TOML schemas, parallel walk logic, and parallel cache files.
- **Bespoke caching.** mise's `sources`/`outputs` gives mtime-based skip-when-fresh, but the cache files contain plaintext secrets at mode 600 — adequate for a local laptop, but the encryption story is "trust the filesystem."
- **Tera template references are nested** (`{{ secrets.git.work.email }}`); the env-var pipeline is flat (`MISE_GITHUB_TOKEN`). The two shapes do not unify.

[fnox](https://github.com/jdx/fnox) is a secrets manager built around the same use cases: declare secrets once, resolve from configurable providers (1Password, age, AWS Secrets Manager, etc.), inject into env or expose via `fnox export`. Its [mise plugin](https://github.com/jdx/mise-env-fnox) auto-injects fnox secrets as env vars on directory entry, and `fnox sync --provider age` produces a gitignored `fnox.local.toml` whose secret values are re-encrypted with age — yielding fully-offline resolution after a one-time sync.

## Decision

1. **Adopt fnox as the single secrets source of truth.** A single committed `fnox.toml` declares every secret (former runtime env vars + former template values), referencing 1Password via the `op` provider as today.

2. **Use age sync for offline resolution.** Each machine generates an age key (or registers an existing SSH key as an age recipient), runs `fnox sync --provider age --config fnox.local.toml` once, and from then on every fnox lookup decrypts locally. This eliminates per-shell `op signin` and removes 1Password from the hot path.

3. **Use the `mise-env-fnox` plugin to auto-inject env vars.** Mise activates the plugin on shell startup; runtime env vars (`MISE_GITHUB_TOKEN`, etc.) become available without `source ~/.config/dotfiles/secrets.fish`. The existing `secrets.{env,fish}` mechanism is removed.

4. **Flatten Tera template references.** Templates that previously read `{{ secrets.git.work.email }}` are rewritten to read `{{ env.GIT_WORK_EMAIL }}`. `_render-context` no longer maintains a parallel nested-secrets layer; secrets enter the context as env vars via the same channel as everything else.

5. **Remove the homegrown infrastructure.** `mise/tasks/secrets`, `mise/tasks/secrets-templates`, `vars/runtime-secrets.toml`, and `vars/secrets.toml` are deleted. The only secrets-related code that remains is whatever `_render-context` needs to expose env vars to Tera.

6. **fnox profiles map onto dotfiles profiles.** `[profiles.personal.secrets]` etc. in `fnox.toml` mirror `DOTFILES_PROFILE`. The mise plugin's `profile = "{{env.MISE_ENV}}"` selector keeps the two systems in lockstep.

## Alternatives considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Keep homegrown infrastructure, fix the per-shell auth** | Possible (e.g., bootstrap `OP_SESSION_*` from a keychain entry, or use service-account tokens), but doesn't address the two-manifest duplication, the bespoke caching, or the cleartext-on-disk story. We'd still own ~400 lines of bash for what fnox does in a binary. |
| **op service account token + direct calls everywhere** | Solves auth-per-shell but keeps every render online and dependent on 1Password's CLI uptime. age sync gives offline resolution as a free side effect. |
| **Pure age, no 1Password** | Loses the team-shareable vault UX. Items still rotate by editing 1P; we want age as a local cache, not the source of truth. |
| **Vault-style daemon (e.g., gopass agent, pass)** | More moving parts than fnox; weaker mise integration. |
| **Re-implement fnox-style sync ourselves** | Wrong NIH bet. We are not in the secret-manager business. |

## Consequences

**Positive**

- One manifest (`fnox.toml`) instead of two parallel ones.
- After `fnox sync`, secret resolution is offline, fast, and survives `op` session expiry.
- Env var loading happens via the well-trodden mise plugin path; shells stop sourcing custom files.
- Deleting `mise/tasks/secrets*` (~400 lines of bash) reduces surface area.
- ADR 0002's profile system gets a cleaner secrets story (`[profiles.personal.secrets]` directly in `fnox.toml`).

**Negative**

- New machine setup requires extra steps: install fnox via mise, generate or register an age key, run `fnox sync` once. Captured in the bootstrap runbook.
- Re-encryption tax when adding a team member or rotating an age key (`fnox reencrypt`); not relevant for single-user dotfiles today but worth noting.
- Templates change shape. `{{ secrets.git.work.email }}` → `{{ env.GIT_WORK_EMAIL }}` is a one-time rewrite, but it touches every template that referenced template secrets.
- 1Password item references must be expressible in fnox's reference grammar. Items currently named with slashes (e.g. `git/work`) collide with fnox's `Item/field` syntax and may need renaming to e.g. `Git Work` or addressing via the full `op://Private/git work/email` form.

**Neutral**

- The `OP_SERVICE_ACCOUNT_TOKEN` bootstrap pattern (token encrypted with age, decrypted at fnox load time) is recommended but not required as long as `op` is interactively signed in for the initial sync.
- Per-shell `op` auth was always a workaround; this just retires the workaround.

## Migration plan

1. Add `fnox` to `mise.toml` `[tools]` and the `mise-env-fnox` plugin to `[plugins]`. Wire `[env]._.fnox-env = { tools = true, profile = "{{env.MISE_ENV}}" }`.
2. Generate (or designate) an age key. Add the public key as a recipient in `fnox.toml`.
3. Convert every entry from `vars/runtime-secrets.toml` and `vars/secrets.toml` into a flat `[secrets]` (or `[profiles.<name>.secrets]`) entry in `fnox.toml`, sourced from the `op` provider.
4. Run `fnox sync --provider age --config fnox.local.toml` once with `op` signed in to populate the offline cache.
5. Rewrite every Tera template reference of the form `{{ secrets.X.Y.Z }}` to `{{ env.X_Y_Z | upper }}` (or pre-flattened name).
6. Update `mise/tasks/_render-context` to read `fnox export --format json` (filtered to current profile) and merge as flat env-style keys into the Tera context.
7. Remove `.zshrc` / `.bashrc` lines that source `secrets.env`. Remove `mise/tasks/secrets`, `mise/tasks/secrets-templates`, `vars/runtime-secrets.toml`, `vars/secrets.toml`.
8. Update `.gitignore` to ignore `fnox.local.toml` (and unignore the now-removed `secrets.env` / `secrets.fish` / `secrets.json` lines).
9. Update bootstrap docs (`README.md` / `ARCHITECTURE.md`) with the new "first-time on a machine" steps: install fnox via mise, drop in age key, `fnox sync`.

## References

- [fnox documentation](https://github.com/jdx/fnox)
- [mise-env-fnox plugin](https://github.com/jdx/mise-env-fnox)
- ADR [0001 — mise as primary tool manager](0001-mise-primary-tool-management.md)
- ADR [0002 — Environment-variable-based profile system](0002-profile-system.md)
