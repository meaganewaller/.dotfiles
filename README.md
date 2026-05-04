# dotfiles

[![Test Dotfiles Setup](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml/badge.svg)](https://github.com/meaganewaller/.dotfiles/actions/workflows/test-dotfiles-setup.yml)

Profile-aware dotfiles and development environment for macOS. Features deep Claude Code integration ("Dev OS"), unified theming, and infrastructure-as-code approach to machine setup.

## Features

- **Profile System** - `work`, `personal`, `server`, `container` profiles (driven by `MISE_ENV`) control which tools, configs, and git identities are active
- **mise-driven setup** - All install/link/unlink/doctor flows are mise tasks under `mise/tasks/`; no bespoke install script to maintain
- **Modular packages** - Configs live in `packages/<category>/<tool>/` with per-tool `tool.toml` manifests declaring link targets, profile gating, and Tera templates
- **Claude Code Integration** - Hooks for telemetry, cues for contextual guidance, skills for reusable workflows, governance for policy traceability
- **Theme System** - Unified dark/light mode across terminal, editor, and shell with `theme set <name>`
- **mise-first tooling** - Runtimes and CLIs prefer mise (`mise/config.<profile>.toml`); Homebrew/apt only for casks, OS integration, and tools mise cannot install
- **Secrets via fnox** - `fnox.toml` + age/1Password backends inject secrets as env vars on directory entry (see [ADR 0005](./docs/architecture/0005-fnox-for-secrets-management.md))
- **Idempotent Setup** - Run setup multiple times safely; symlinks and rendered configs converge to desired state

## Quick Start

### Fresh Machine (curl bootstrap)

```bash
export DOTFILES_PROFILE=work   # or personal, server, container
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` installs minimum-viable deps (brew/git on macOS, curl/git on Linux), installs `mise`, clones the repo, and hands off to `mise run setup --profile <PROFILE>`.

### Existing Clone

```bash
mise trust
mise run setup --profile work
```

### Dry Run (preview changes)

```bash
mise run setup --profile work --dry-run
mise run link  --profile work --dry-run
```

### Targeted Re-link

```bash
mise run link --profile work --only vcs              # one package
mise run link --profile work --only vcs:git,shells:fish
mise run link --profile work --except wm
```

## Commands

### Top-level mise tasks

All setup/maintenance flows live in `mise/tasks/`:

```bash
mise run setup    --profile work        # Full setup: deps → link → install → auth → brew → fonts
mise run link     --profile work        # Render templates + symlink packages into $HOME
mise run unlink   --profile work        # Remove symlinks created by link
mise run doctor                         # Health check: binaries, auth, symlinks, signing keys
mise run deps                           # OS-level deps mise can't manage (curl, git, gh, op)
mise run auth                           # Sign into GitHub CLI and 1Password
mise run brew     --profile work        # Run profile's brew_layers
mise run fonts                          # Install Nerd Fonts and custom fonts
```

Common flags on `setup`: `--only <packages>`, `--skip-auth`, `--skip-brew`, `--dry-run`.

### Package-level tasks

Tasks scoped to a package live under `packages/<category>/mise/tasks/` and are invoked with the monorepo prefix:

```bash
mise run //packages/vcs:git:init                           # Install global git hooks
mise run //packages/vcs:git:sync-signing-keys -- --profile work
```

### Theme Management

```bash
theme list                   # Show available themes
theme set <name>             # Apply theme across all apps
theme dark | light           # Quick mode switch
theme current                # Show active theme
```

## Repository Structure

```
.dotfiles/
├── bootstrap.sh             # Stage 0: curl-able bootstrap → mise run setup
├── mise.toml                # Repo-level mise config (monorepo root)
├── mise/
│   ├── tasks/               # Top-level tasks: setup, link, unlink, doctor, deps, auth, brew, fonts
│   └── config.<profile>.toml # Profile-layered tool/var configs
├── packages/                # Modular config packages (link source of truth)
│   ├── editors/             # nvim, …
│   ├── shells/              # bash, fish, zsh, atuin, starship
│   ├── terminals/           # ghostty, wezterm, tmux
│   ├── vcs/                 # git, gh, lazygit (+ package-level mise tasks)
│   ├── ssh/                 # ssh client config + known_hosts
│   ├── wm/                  # aerospace, sketchybar, borders
│   └── scripts/             # personal CLIs (theme, pull-everything, …)
│       └── <pkg>/
│           ├── package.toml # profile/os gating, post_link hooks
│           ├── tool.toml    # link/template manifest per tool
│           └── *.tmpl       # Tera templates (rendered into .rendered/)
├── vars/                    # Tera context: common, per-profile, per-OS
├── fnox.toml                # Secrets manifest (age/1Password backends)
├── brewfiles/               # Homebrew bundles by category
├── home/                    # Legacy: configs still being migrated into packages/
│   └── .claude/             # Claude Code hooks, cues, skills, governance
├── lib/common.sh            # Shared shell helpers used by mise tasks
├── docs/architecture/       # Dotfiles ADRs
└── test/                    # BATS test suite
```

> Migration in progress: configs under `home/` are being moved into `packages/<category>/<tool>/` with proper `tool.toml` manifests. Until that's done, the link task handles both sources.

## Profiles

| Profile | Use Case | Brewfiles | GUI Apps |
|---------|----------|-----------|----------|
| `work` | Work machine | base, gui, dev, infra | Yes |
| `personal` | Personal machine | base, gui, creative | Yes |
| `server` | Remote servers | base | No |
| `container` | Devcontainers | minimal | No |

Set via `MISE_ENV` (canonical), `DOTFILES_PROFILE`, or `--profile` on any task. `mise run setup` exports both so layered configs and child task invocations stay aligned.

Profiles also control:
- Git identity (`includeIf` in the rendered `.gitconfig`)
- SSH config includes
- Which packages/tools get linked (`profiles = [...]` in `package.toml` / `tool.toml`)
- Repo mise layers: `mise/config.<profile>.toml` overlays `mise.toml` for tools, env, and `brew_layers` (see [ARCHITECTURE.md](./ARCHITECTURE.md))
- Tera template context: `vars/<profile>.toml` merged with `vars/common.toml` and `vars/os/<os>.toml`

## Claude Code Integration

This repo includes extensive Claude Code customization:

### Hooks

Event-driven scripts that run during Claude Code sessions:
- **PreToolUse** - Guards for large files, bulk operations, git safety
- **PostToolUse** - Impact tracking, loop detection, tradeoff capture
- **SessionStart/End** - Context injection, session tracking

### Cues

Pattern-triggered contextual guidance injected into prompts:
- `commit/` - Git commit best practices
- `migration/` - Database migration guidance
- `env/` - Secrets handling reminders
- `large-files/` - Chunked reading strategies

### Skills

Reusable workflows invoked with `/skill-name`:
- `/standup` - Generate standup from recent activity
- `/weekly-review` - Aggregate weekly accomplishments
- `/code-review` - Structured code review
- `/root-cause` - 5-Whys analysis

See [home/.claude/README.md](./home/.claude/README.md) for full documentation.

## Global Git Hooks

`packages/vcs/git/hooks/` is wired in as the global hooks path on link. The pre-commit hook:

- Blocks direct commits to `main`/`master` (override with `ALLOW_COMMIT_TO_MAIN=1`)
- Flags staged lines that look like secrets (`api_key`, `password`, `token`, …)
- Rejects any staged file >5MB

Bypass with `git commit --no-verify` when intentional.

## Making Changes

1. **Add or edit a package** - Drop files under `packages/<category>/<tool>/` and declare them in `tool.toml`:
   ```toml
   [tool]
   name = "fish"
   target = "~/.config/fish"
   profiles = ["work", "personal"]   # optional gating

   [[link]]
   src  = "config.fish.tmpl"
   dest = "~/.config/fish/config.fish"
   ```
   `*.tmpl` files are rendered with Tera against the profile/OS context before linking.
2. **Re-link** - `mise run link --profile <p>` (or `--only <pkg>` to scope)
3. **Add CLIs/runtimes** - Prefer `mise/config.<profile>.toml`; use `brewfiles/*.Brewfile` only for casks, OS packages, and tools mise can't cover. See [ARCHITECTURE.md](./ARCHITECTURE.md#tool-management-policy).
4. **Add a task** - New top-level tasks go in `mise/tasks/<name>`; package-scoped tasks go in `packages/<category>/mise/tasks/<tool>/<name>` and are invoked with the `//packages/<category>:<tool>:<name>` prefix.
5. **Secrets** - Edit `fnox.toml`, then `fnox sync` (or rerun `mise run setup`). See [ADR 0005](./docs/architecture/0005-fnox-for-secrets-management.md).
6. **Verify** - `mise run doctor` checks binaries, auth, symlinks, and signing keys.

Changes to `home/.claude/` are picked up by `mise run link` along with everything else; no separate Claude installer.

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design, directory structure, data flows |
| [docs/architecture/](./docs/architecture/) | **Dotfiles repo** ADRs (bootstrap, tools, profiles) |
| [home/.claude/README.md](./home/.claude/README.md) | Claude Code hooks, cues, skills, governance |
| [home/.claude/docs/architecture/](./home/.claude/docs/architecture/) | **Claude Code** ADRs (hooks, cues, Dev OS) |
| [governance/README.md](./governance/README.md) | Dotfiles vs Claude governance layout |
| [governance/policies/tool-management.md](./governance/policies/tool-management.md) | mise-first tool policy |
| [docs/architecture/0005-fnox-for-secrets-management.md](./docs/architecture/0005-fnox-for-secrets-management.md) | Secrets pipeline (fnox + age/1Password) |
| `mise tasks` | Live task reference (descriptions are in each task's `#MISE` header) |

## Testing

```bash
./test/run-tests.sh          # Run all BATS tests
bats test/hooks/             # Run hook tests only
shellcheck bin/*             # Lint shell scripts
```

## License

MIT
