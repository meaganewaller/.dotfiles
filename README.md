# my dotfiles

a profile-aware, self-healing, one-command machine bootstrap for macOS (and eventually linux)

this repo treats your dev env like infra:

- stage 0 bootstrap via `curl` - not even git required up front
- github cli (`gh`) and 1password cli (`op`) for auth + identity
- homebrew for system packages and gui apps
- mise for all langauges, runtimes, and dev tooling
- profile-aware dotfile overlays (`work`, `personal`, `container`, `server`)
- idempotent, safe symlinks for everything in `$HOME`

a brand new machine can go from zero to fully configured with these steps:

## quick install (fresh machine)

on a brand new mac:

```bash
export DOTFILES_PROFILE=work   # or personal / server / container
curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap/remote-bootstrap.sh | bash
```

## repo structure

```bash
dotfiles/
├── bin/                          # Low-level helpers
│   ├── link-dotfiles             # Orchestrates symlinking for profiles
│   └── make-symlink              # Safe, idempotent file/dir symlinker
│
├── bootstrap/                    # Stage 0 + system provisioning
│   ├── remote-bootstrap.sh       # curl entrypoint (no git required)
│   ├── Brewfile.common           # Shared system packages
│   └── Brewfile.work             # Work-only packages
│
├── home/                         # Actual dotfiles (symlinked into $HOME)
│   ├── .bashrc
│   ├── .config/
│   │   ├── karabiner/
│   │   ├── nvim/
│   │   ├── wezterm/
│   │   └── zsh/
│   ├── .editorconfig
│   ├── .gitconfig
│   ├── .gitconfig.work
│   ├── .gitconfig.personal
│   ├── .hammerspoon/
│   ├── .ssh/
│   ├── .zshenv
│   └── .zshrc
│
├── mise/                         # mise toolchain + tasks
│   └── config.toml
│
├── install.sh                    # Stage 2 orchestrator
├── bootstrap.sh                  # Thin wrapper → install.sh
└── .env                          # Optional local overrides (not committed)
```

## how it works

### stage 0 - `remote-bootstrap.sh` (runs via curl)

this is the only thing you need on a fresh machine.

it:

- installs homebrew (macos)
- installs `git`, `gh`, and `op`
- authenticates:
    - github via `gh auth login`
    - 1password via `op signin`
- reads git identity + signing keys from 1password items
- generates machine-specific git config:
    - `~/.gitconfig.work`
    - `~/.gitconfig.personal`
    - `~/.gitconfig.local` with `includeIf` rules
- clones the dotfiles repo
- hands off to `bootstrap.sh`

imperative and pragmatic, so we can reach the declarative parts safely.

### stage 1 - `bootstrap.sh`

a very thin wrapper:

- respects `$DOTFILES_PROFILE`
- calls `install.sh`

all real logic lives elsewher

### stage 2 - `install.sh`

this is the convergence engine

it:

1. links all dotfiles via `bin/link-dotfiles`
2. loads homebrew shell environment
3. runs `brew bundle`:
    - `bootstrap/Brewfile.common`
    - `bootstrap/Brewfile.$PROFILE`
4. relies on mise to manage:
    - languages
    - runtimes
    - global dev tools

it is safe to re-run at any time.

### stage 3 - `bin/link-dotfiles` + `bin/make-symlink`

all symlinking goes through `make_symlink`, which guarantees:

- existing files are backed up
- incorrect symlinks are replaced
- nested paths work (.ssh/config, .config/nvim, etc)
- re-running is always safe

profiles control what gets linked.

## profiles

profiles represent machine intent, not just identity:

- `work`
- `personal`
- `server`
- `container`

profile affects:
- which Brewfiles are applied
- which dotfiles are linked
- git identity (via includeIf rulesS)
- editor and shell configuration

right now, profiles are implemented procedurally in `bin/link-dotfiles` and `install.sh`.

eventually this will probably move to a declarative manifest, so:

> profiles describe intent, scripts enforce it.

but we're not there yet, and this gets the job done in the meantime.

## daily workflow

you almost never need to touch the bootstrap again.

### relink dotfiles

```bash
bin/link-dotfiles --profile work
```

### install/update runtimes and tools

```bash
mise install
```

### update system packages

```bash
brew bundle --file=bootstrap/Brewfile.common
brew bundle --file=bootstrap/Brewfile.work
```

### re-run full convergence

```bash
./install.sh --profile work
```

everything is designed to be safely repeatable

## design principles


### declarative where possible, imperative where necessary

bootstap is imperative because reality isn't neat. everything after that should be convergent and reproducible.

### profiles are first-class

a machine isn't just "my laptop". it has an intent, constaints, and trust boundaries, profiles make that explicit.

### idempotence everywhere

every command should be safe to re-run

### boring is the goal

when this works, it should feel unremarkable.

## making changes

- edit dotfiles -> `home/`
- add system packages -> `bootstrap/Brewfile.*`
- add runtimes/tools -> `mise/config.toml`
- update linking logic -> `bin/link-dotfiles`
- re-run `install.sh` to converge