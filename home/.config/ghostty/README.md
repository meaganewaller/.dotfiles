# Ghostty Configuration

<div align="center">

[![Ghostty](https://img.shields.io/badge/ghostty-%3E%3D1.2-purple)](https://ghostty.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Maintenance](https://img.shields.io/badge/maintained-yes-brightgreen)]()

</div>

---

## Architecture

```text
ghostty/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── .gitignore
├── .editorconfig
├── config                          # Entrypoint (orchestrator)
├── conf.d/
│   ├── 00-core.conf
│   ├── 10-font.conf
│   ├── 20-colors.conf
│   ├── 30-keybindings.conf
│   ├── 40-window.conf
│   ├── 50-cursor.conf
│   ├── 60-mouse.conf
│   ├── 70-security.conf
│   ├── 80-performance.conf
│   ├── 85-platform.conf
│   └── 99-local.conf              # GITIGNORED
├── shaders/
│   └── *.glsl                     # Various collected shaders
└── themes/
    ├── palettes/
    │   └── *.lua                     # Various collected themes
    ├── active.lua
    ├── init.lua
    └── schema.lua
```

## Quick Start

One command handles everything, including installing dependencies.

```bash
mise run ghostty:install
```

## Module Map

| File                  | Domain                               | Source of Truth       |
| --------------------- | ------------------------------------ | --------------------- |
| `config`              | Orchestrator                         | —                     |
| `00-core.conf`        | Shell integration, fundamentals      | —                     |
| `10-font.conf`        | Typography, ligatures, icon mapping  | ✦ Fonts & Icons       |
| `20-colors.conf`      | Palette, cursor, selection colors    | ✦ Colors & Highlights |
| `30-keybindings.conf` | All keyboard shortcuts               | —                     |
| `40-window.conf`      | Chrome, padding, opacity, sizing     | —                     |
| `50-cursor.conf`      | Cursor shape and behavior            | —                     |
| `60-mouse.conf`       | Mouse behavior, selection            | —                     |
| `70-security.conf`    | Clipboard, permissions, updates      | —                     |
| `80-performance.conf` | Scrollback, shaders                  | —                     |
| `85-platform.conf`    | macOS / Linux / WSL specifics        | —                     |
| `99-local.conf`       | Machine-local overrides (gitignored) | —                     |

## Keybindings

<details>
<summary>Click to expand</summary>

| Action          | Binding                  |
| --------------- | ------------------------ |
| Split right     | `Ctrl+Shift+\`           |
| Split down      | `Ctrl+Shift+-`           |
| Navigate split  | `Ctrl+Shift+H/J/K/L`     |
| Resize split    | `Ctrl+Shift+Alt+H/J/K/L` |
| Zoom split      | `Ctrl+Shift+Z`           |
| Equalize splits | `Ctrl+Shift+E`           |
| New tab         | `Ctrl+Shift+T`           |
| Close surface   | `Ctrl+Shift+W`           |
| Tab 1–9         | `Ctrl+Shift+1–9`         |
| Quick terminal  | `Ctrl+\`` (global)       |
| Reload config   | `Ctrl+Shift+,`           |
| Inspector       | `Ctrl+Shift+I`           |

</details>

## Diagnostics

```bash
ghostty +show-config       # Resolved config (all modules merged)
ghostty +list-themes       # Available built-in themes
ghostty +list-fonts        # Detected system fonts
ghostty +list-keybinds     # Active keybindings
ghostty +list-actions      # All bindable actions
```

## License

[MIT](LICENSE)
