# ssh package

Manages `~/.ssh/` config (*not* keys). Keys live in 1Password's SSH agent; this package only configures the client.

## Files

- `config.tmpl` → `~/.ssh/config` — main client config, points at the
  1Password agent socket and includes `conf.d/*.conf`
- `conf.d/work.tmpl` → `~/.ssh/conf.d/work.conf` — work-only host blocks
- `conf.d/personal.tmpl` → `~/.ssh/conf.d/personal.conf` — personal-only host blocks
- `conf.d/github.conf` → `~/.ssh/conf.d/github.conf` — github-personal, github-work aliases
- `known_hosts_static` → `~/.ssh/known_hosts_static` — pinned host keys

All files are linked with mode 600 via `tool.mode = "private"`.

## Adding a new host

1. Decide which profile(s) it applies to.
2. Add a Host block to `conf.d/<profile>.tmpl` (or `conf.d/github.conf`
   for cross-profile static entries).
3. `mise run link --only ssh` to apply.

## Adding a pinned host key

1. Get the host's pubkey: `ssh-keyscan -t ed25519 hostname`
2. Append the line to `known_hosts_static`.
3. `mise run link --only ssh`.

## What's NOT here

- Private keys (`id_*`) — managed by 1Password's SSH agent
- `known_hosts` — left unmanaged so per-machine TOFU still works
- `authorized_keys` — that's a server-side concern, not a client config
