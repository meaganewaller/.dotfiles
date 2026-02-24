# Personal profile

Settings for **personal** (non-work) use. This profile is applied on top of **common** when the personal profile is selected in Claude Code.

## What this profile changes

### `basics.jsonc`

- **Statusline**: Overrides common’s `ccstatusline` with a custom script:
  - `$HOME/github/meaganewaller/.dotfiles/home/.claude/scripts/personal/statusline.sh`

All other behavior (model, hooks, permissions, plugins) comes from **common**. Personal does not define its own plugins or permissions, so it uses common’s defaults.

## When to use

Choose the **personal** profile when working on:

- Side projects
- Open source or hobby repos
- Anything outside the work AWS/Gusto environment

If you need a different model or env for personal use, add overrides in `basics.jsonc` (e.g. `model`, `env`).
