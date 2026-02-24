# Claude Code settings

This directory holds [Claude Code](https://docs.anthropic.com/claude-code) settings as JSONC files, organized by **profile**. Settings are merged when you run `mise run claude`: **common** is always applied first, then the active profile (e.g. **personal** or **work**) overrides or extends as needed.

## Layout

```
settings/
├── README.md           # this file
├── common/             # shared settings (always applied)
│   ├── README.md
│   ├── basics.jsonc
│   ├── hooks.jsonc
│   ├── plugins.jsonc
│   └── permissions/
│       ├── read.jsonc
│       ├── write.jsonc
│       ├── bash.jsonc
│       ├── tools.jsonc
│       ├── skills.jsonc
│       └── additional-dirs.jsonc
├── personal/           # personal / non-work profile
│   ├── README.md
│   └── basics.jsonc
└── work/               # work profile (e.g. Gusto, AWS)
    ├── README.md
    ├── basics.jsonc
    └── plugins.jsonc
```

## Profiles

| Profile   | Purpose |
|----------|---------|
| **common**   | Shared defaults: model, statusline, hooks, permissions, allowed tools. Used by every session. |
| **personal** | Personal projects: custom statusline and any personal-only overrides. |
| **work**     | Work environment: AWS/Bedrock, Gusto plugins, work-specific statusline and env. |

Switching profiles is done via Claude Code’s profile selector (or equivalent); the chosen profile’s files are merged on top of `common`.

## File format

- All config files use **JSONC** (JSON with `//` comments).
- They reference the schema: `https://json.schemastore.org/claude-code-settings.json`.
- Keys in profile files override the same keys from `common`; other keys are additive (e.g. `env`, `permissions.allow`).

For details on what each profile configures, see the README in each profile directory.
