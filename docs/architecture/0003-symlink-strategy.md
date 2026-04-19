---
status: accepted
date: 2026-04-19
deciders: [meaganewaller]
---

# 3. Symlink strategy for dotfiles deployment

## Status

Accepted

## Context

Dotfiles need to get from the repository (`home/`) into `$HOME` where tools expect them. The deployment mechanism must be:

- **Idempotent** — safe to run repeatedly without side effects
- **Transparent** — edits in `$HOME` are immediately visible in the repo (and vice versa)
- **Reversible** — easy to undo without data loss
- **Profile-aware** — some files should only appear for certain profiles (see [ADR 0002](0002-profile-system.md))

## Decision

1. **Symlinks from `$HOME` into the repo** — `~/.zshrc` -> `.dotfiles/home/.zshrc`. Edits in either location are the same file.

2. **Directory-level symlinks by default** — `run ".config/nvim"` symlinks the entire directory, not individual files. This avoids maintaining a manifest of every file within a config directory.

3. **Exceptions for directories that don't tolerate symlinks**:
   - **Fish shell** (`~/.config/fish/`) — Fish writes runtime files (e.g., `fish_variables`) into its config directory. A directory symlink would put these generated files into the repo. Instead, `run_dir_contents` symlinks individual files within the directory.

4. **`make-symlink` helper** provides idempotent symlink creation:
   - Creates parent directories as needed
   - Backs up existing files to `*.backup` before replacing
   - Skips if the symlink already points to the correct target
   - Never deletes — only creates or backs up

5. **Conditional linking** — `bin/link-dotfiles` uses profile checks to link GUI-specific files (hammerspoon, karabiner, sketchybar) only for work/personal profiles.

6. **Files never symlinked**: `README.md` files (repo documentation only), `*.example` files (templates).

## Alternatives considered

| Alternative | Why not chosen |
|-------------|----------------|
| **Copy files** | Edits in `$HOME` aren't reflected in the repo; requires a sync step; easy to lose changes |
| **GNU Stow** | Adds a system dependency; its directory-tree mirroring is less flexible than explicit `run` calls for profile-conditional linking |
| **Git bare repo with `$HOME` as worktree** | Every `git status` in `$HOME` shows untracked files; `.gitignore` becomes unmanageable; no profile layering |
| **Ansible/Chef/Nix** | Heavyweight for personal dotfiles; steep learning curve for contributors; overkill for the problem |

## Consequences

**Positive**

- Zero-copy: changes are instantly visible in both the repo and the live config
- Backup-on-replace means no data loss during re-linking
- Simple mental model: `home/` mirrors `$HOME`

**Negative**

- Directory symlinks mean the entire directory is either linked or not — you can't exclude individual files within a directory (mitigated by the `run_dir_contents` exception pattern)
- Tools that write into their config directory (like Fish) need special handling
- Moving the repo breaks all symlinks (mitigated by using absolute paths)

**Neutral**

- `ls -la` in `$HOME` shows symlinks, which is visually noisy but also makes it obvious which files are managed
