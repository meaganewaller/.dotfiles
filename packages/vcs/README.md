# vcs package

Git, GitHub CLI, and lazygit — everything version-control-shaped.

## Tools

- `git/` — main git config, includes, hooks, ignore, attributes
- `gh/` — GitHub CLI config (auth tokens are NOT managed here)
- `lazygit/` — lazygit TUI config

## Identity routing

Your work and personal identities are split via `~/.gitconfig.local`'s
`includeIf` blocks. The split happens by:

1. **Remote URL** (most reliable): repos on `github.com/gusto/*` get the work identity, repos on `github.com/meaganewaller/*` get personal.
2. **Local directory** (fallback): repos under `~/workspace/` get work, under `~/github/meaganewaller/` get personal.

If you clone a repo that doesn't match any pattern, `useConfigOnly = true`
will block your first commit with a clear error so you can decide.

## Hooks

Global hooks live in `git/hooks/` and apply to every repo that doesn't have
its own `.git/hooks/`. Currently:

- `pre-commit` — blocks commits to main, scans for obvious secrets, rejects files >5MB
- `commit-msg` — placeholder

Disable globally for a single repo: `git config --local core.hooksPath .git/hooks`
Bypass for one commit: `git commit --no-verify`

## Adding a new identity

1. Add the secret to 1Password under `git/<name>` with `email` and `signingkey` fields.
2. Add it to `vars/secrets.toml`.
3. Create `git/includes/<name>.tmpl`.
4. Add a `[[link]]` entry in `git/tool.toml`.
5. Add `includeIf` rules in `git/includes/local.tmpl`.
6. `mise run link --only vcs`.

## What's NOT here

- `gh` auth tokens (`hosts.yml`) — let `gh auth login` manage those per machine
- Per-repo configs — those belong in the repo, not here
