---
status: accepted
date: 2026-04-19
deciders: [meaganewaller]
---

# 2. Environment-variable-based profile system

## Status

Accepted

## Context

This dotfiles repository manages configuration across multiple machine contexts: a work macOS laptop, a personal macOS machine, headless servers, and devcontainers. Each context needs a different subset of tools, git identity, SSH keys, and shell behaviour.

Without a profile system, the options are:

- **Single config for everything** — leads to work tools on personal machines and vice versa, wrong git identity on commits, and unnecessary packages on servers.
- **Separate branches per machine** — diverges quickly and merges become painful.
- **Separate repos** — duplicates shared config (shell, editor, git aliases).

We need a way to share common configuration while varying specific layers per context.

## Decision

1. **Four named profiles** — `work`, `personal`, `server`, `container` — cover the current machine contexts. Profiles are validated at install time against `VALID_PROFILES` in `lib/common.sh`.

2. **`DOTFILES_PROFILE` environment variable** is the primary selection mechanism, defaulting to `work`. It can also be passed as `--profile <name>` to `install.sh`, `bin/link-dotfiles`, and the Claude Code installer.

3. **Layered configuration** — each subsystem uses a common base plus profile-specific overrides:
   - **Brewfiles**: profile selects which layers to install (`base gui dev infra` for work, `base gui creative dev infra` for personal, none for server/container).
   - **mise**: `MISE_ENV` is set from `DOTFILES_PROFILE`; `config.<profile>.toml` layers on `config.toml`.
   - **Git identity**: `.gitconfig` uses `includeIf` to load `.gitconfig.work` or `.gitconfig.personal`.
   - **SSH**: `.ssh/config` includes `.ssh/config.<profile>`.
   - **Claude Code**: settings merged from `settings/common/` + `settings/<profile>/`.
   - **Symlinks**: `bin/link-dotfiles` conditionally links profile-specific files (e.g., hammerspoon, karabiner only on macOS profiles).

4. **Server and container profiles** intentionally use common-only configs — they are minimal environments with no GUI or profile-specific tooling. Stub files exist so the profile system resolves explicitly rather than silently falling back.

## Alternatives considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Git branches per machine** | Shared config diverges; merges are error-prone and manual |
| **Symlink farm tool (GNU Stow)** | Adds a dependency; doesn't solve the layering/override problem |
| **Hostname-based detection** | Brittle (hostnames change), doesn't generalise to containers or new machines |
| **Interactive installer prompts** | Slower, not idempotent, harder to automate in CI |

## Consequences

**Positive**

- Same repo, same branch for all machines — `git pull` gets everything
- Adding a new profile is additive: create stub files, add to `VALID_PROFILES`, done
- `install.sh` is idempotent and non-interactive (good for CI and fresh machine bootstrap)

**Negative**

- Profile must be set correctly; wrong profile = wrong git identity on commits (mitigated by `validate_profile` and defaulting to `work`)
- Server/container profiles carry common config that may include tools they don't need (acceptable tradeoff for simplicity)

**Neutral**

- Adding a fifth profile (e.g., `ci`) requires touching several files but the pattern is well-established
