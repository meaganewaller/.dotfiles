# my dotfiles

a fully declarative, profile-aware, self-healing development environment.

- [scope doctor](https://oscope-dev.github.io/scope/) groups converge the machine into a known-good state
- [mise](https://mise.jdx.dev/) manages all programming languages, runtimes, and dev tooling
- profile-aware dotfile overlays (`work`, `personal`, `server`)
- idempotent symlinks that are safe, reversible, and structured

everything in here works together so that a new mac can go from zero to fully configured in one command.

## quick install

on a fresh mac:

```bash
export DOTFILES_PROFILE=work # or personal / server
sh -c "$(curl -fsSL https://raw.githubusercontent.com/meaganewaller/.dotfiles/main/bootstrap.sh)"
```

this bootstrap includes:

- homebrew
- mise
- karabiner
- hammerspoon
- ssh + keys
- git + identity
- dotfiles symlinked into `$HOME`
- full scope doctor run

you end up with a fully converged, reproducible dev machine.

## repo structure

below is the actual repo layout, with annotations explaining what each piece does:

```bash
dotfiles/
├── .gitignore
│
├── bin/                           # User-level helpers
│   ├── link-dotfiles              # Symlink $DOTFILES_ROOT/home → $HOME
│   └── make-symlink               # Safe, idempotent file/dir symlinker
│
├── bootstrap.sh                   # Entry point (curl → clone → install)
│
├── config/                        # Declarative system package definitions
│   ├── Brewfile.common            # Shared across all profiles
│   └── Brewfile.work              # Additional packages for work machines
│
├── home/                          # Actual dotfiles to be symlinked
│   ├── .bashrc
│   ├── .config/                   # App configs that belong in ~/.config
│   │   ├── karabiner/             # Karabiner-Elements config
│   │   │   └── karabiner.json
│   │   ├── nvim/                  # Full NeoVim config
│   │   ├── wezterm/               # WezTerm config ecosystem
│   │   └── zsh/                   # ZSH modules (aliases, paths, p10k, etc.)
│   ├── .editorconfig
│   ├── .gitconfig                 # Base git config
│   ├── .gitconfig.personal
│   ├── .gitconfig.work
│   ├── .hammerspoon/              # Hammerspoon config + custom spoons
│   ├── .ssh/                      # SSH configs (no keys)
│   ├── .zshenv                    # Login env
│   └── .zshrc                     # Shell config
│
├── install.sh                     # Main orchestrator (sync scope, mise, dotfiles)
│
├── mise/                          # mise global toolchain definitions
│   └── config.toml
│
└── scope/                         # Scope Doctor groups + scripts
    ├── bin/                       # Scripts for doctor groups
    │   ├── doctor-git
    │   ├── doctor-hammerspoon
    │   ├── doctor-homebrew
    │   ├── doctor-karabiner
    │   ├── doctor-mise
    │   ├── doctor-os-base
    │   └── doctor-ssh
    ├── git.yaml
    ├── hammerspoon.yaml
    ├── homebrew.yaml
    ├── karabiner.yaml
    ├── mise.yaml
    ├── os-base.yaml
    └── ssh.yaml
```

this design makes every concern explicit and modular.

## how it works

### 1. bootstrap.sh

- clones the repo
- determines profile (or respects `$DOTFILES_PROFILE`)
- installs scope (if needed)
- runs `install.sh`

### 2. install.sh

- syncs `scope/` to `~/.config/scope`
- adds `~/.config/scope/bin` to `$PATH`
- runs all doctor groups in order
- symlinks everything from `home/`

### 3. make-symlink

this ensures every file or directory symlink:

- performs a backup of existing conflicting files
- supports nested paths: `.ssh/config`, `.config/nvim`, `.config/wezterm`
- is fully idempotent and repeatable

no more `rm -rf ~/.config/whatever`.

### 4. scope doctor

each yaml in `scope/` declares a convergence group (homebrew, ssh, mise, etc)

## profiles

profiles define machine intent (work | personal | server)

profile-specific behavior includes:

- git identity
- ssh identity
- additional brew packages
- dotfile overlays
- app installs (e.g., work vs personal GUI apps)

profiles will eventually move to declarative yaml in `profiles/`.

## daily workflow

you rarely need to touch the internals:

### full convergence:

```bash
scope doctor run --extra-config=$HOME/.config/scope
```

### validate without modifying:

```bash
scope doctor run --extra-config=$HOME/.config/scope --fix=false
```

### update plugins

```bash
mise install
brew bundle --file=config/Brewfile.common
brew bundle --file=config/Brewfile.work # if profile=work
```

### re-link dotfiles

```bash
bin/link-dotfiles $DOTFILES_PROFILE
```

## design principles

### declarative > imperative

everything is described in yaml or toml. scripts simply enforce it.

### self-healing

a broken config is just another doctor run away from being fixed.

### profiles as first-class citizens

your environment adapts to who you are on this machine

### idempotence everywhere

every run can be repeated safely

### new machine in 10 minutes

that's the standard this repo is built for

## making changes

- edit configs in `home/`
- add new doctor groups in `scope/`
- add new system packages in `config/Brewfile.*`
- add new languages/tools in `mise/config.toml`
- re-run doctor to confirm convergence

everything should _just work_
