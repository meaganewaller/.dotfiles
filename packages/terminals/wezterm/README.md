# WezTerm configuration

Modular [WezTerm](https://wezterm.org/) setup: tmux-style leader keys, workspaces, per-project layouts, custom tab bar and status line, and optional **Agent Deck** integration for coding agents (Claude, Codex, OpenCode, etc.).

## Requirements

- [WezTerm](https://wezterm.org/installation.html) with Lua config support (default).
- **Fonts (recommended):** primary UI font is **Maple Mono NF CN** with fallbacks to Nerd Font Symbols, emoji, and a runic font. If those are missing, WezTerm falls through the fallback chain; install the fonts you care about or adjust `lua/fonts.lua`.
- **Projects picker:** `lua/projects.lua` lists project files with `ls`; **macOS/Linux** with a normal shell are assumed. On Windows, project discovery may not run as written.

## Layout of this directory

| Path | Role |
|------|------|
| `wezterm.lua` | Entry point: builds config, sets leader, loads all modules in order. |
| `scanlines.png` | Subtle tiled overlay on the background (see `lua/colors.lua`). |
| `lua/base.lua` | Core behavior: reload on save, OpenGL, FPS, Wayland, bell, close confirmation allowlist, status update interval. |
| `lua/keys.lua` | Leader bindings, copy mode / search mode tables, workspace switcher, **project launcher** (`leader` + `f`). |
| `lua/fonts.lua` | Font stack, line height, underline, cursor, block glyphs. |
| `lua/colors.lua` | Color scheme name, tab bar colors from theme, layered background (solid + scanlines). |
| `lua/theme.lua` | Central palette: base text, tab bar, agent status colors, work-hours indicator colors. |
| `lua/layout.lua` | Window chrome, padding; on **macOS**, first GUI window is maximized at startup. |
| `lua/agent/` | Agent Deck loader (`deck.lua`), **overlay detection** when the plugin is unavailable (`detection.lua`). |
| `lua/tabs.lua` | Tab bar at bottom, custom tab titles with optional agent icons, width-aware padding. |
| `lua/status.lua` | Left/right status: workspace, date, time, week number, “waiting agent” count, optional work-hours line (non-Windows). |
| `lua/mux.lua` | **Unix domain** for attaching (`unix`); skipped on Windows. |
| `lua/platform.lua` | Per-OS font size, opacity, decorations, blur (macOS), WSL default domain on Windows, **VirtualBox** performance profile on Linux. |
| `lua/projects.lua` | Loads `projects/*.lua`, builds fuzzy workspace/project picker. |
| `lua/utils/time.lua` | Parses pane user vars for work-hours display. |
| `projects/*.lua` | One file per named workspace (see [Projects](#projects)). |

### Load order (`wezterm.lua`)

1. Leader: `Ctrl+a` (1.5s timeout) — change in `wezterm.lua` if desired.  
2. `base` → `keys` → `fonts` → `colors` → `layout` → **agent** → `tabs` → `status` → `mux` → `platform`  

Later modules override earlier settings where they overlap (e.g. `platform` adjusts `font_size` after `fonts`).

## Leader key and tmux mapping

Prefix is **`Ctrl+a`**. Concept mapping:

| Tmux | WezTerm |
|------|---------|
| Session | [Workspace](https://wezterm.org/recipes/workspaces.html) |
| Window | Tab |
| Pane | Pane |
| Prefix | Leader (`Ctrl+a`) |
| Copy mode | Copy mode |

Multiplexing without tmux: [WezTerm multiplexing](https://wezterm.org/multiplexing.html).

## Keybindings

### Leader basics

| Combo | Action |
|-------|--------|
| `Ctrl+a` `Ctrl+a` | Send literal `Ctrl+a` to the shell |
| `leader` + `[` | Enter copy mode |

### Workspaces

| Combo | Action |
|-------|--------|
| `leader` + `$` | Rename current workspace |
| `leader` + `s` | Interactive workspace switcher (tab counts) |
| `leader` + `(` | Previous workspace |
| `leader` + `)` | Next workspace |

### Tabs

| Combo | Action |
|-------|--------|
| `leader` + `c` | New tab (current pane domain) |
| `leader` + `&` | Close current tab (confirm) |
| `leader` + `p` / `n` | Previous / next tab |
| `leader` + `l` | Last active tab |
| `leader` + `,` | Rename current tab (prompt) |
| `leader` + `w` | Tab navigator |
| `leader` + `1`–`9` | Activate tab by index (1-based unless you set `tab_and_split_indices_are_zero_based`) |

### Panes

| Combo | Action |
|-------|--------|
| `leader` + `%` | Split horizontal |
| `leader` + `"` | Split vertical |
| `leader` + `{` / `}` | Rotate panes counter-clockwise / clockwise |
| `leader` + arrow | Activate pane in direction |
| `leader` + `q` | Interactive pane selector |
| `leader` + `z` | Zoom / unzoom pane |
| `leader` + `!` | Move pane to new tab |
| `leader` + `Ctrl` + arrow | Resize pane (5 cells) |
| `leader` + `x` | Close pane (confirm) |

### Launcher and app

| Combo | Action |
|-------|--------|
| `leader` + `Space` | [Quick select](https://wezterm.org/shell-integration.html) (URLs, etc.) |
| `leader` + `f` | **Switch to project** (fuzzy picker; see [Projects](#projects)) |
| `leader` + `d` | Quit application |
| `leader` + `:` | Command palette |
| `leader` + `r` | Reload configuration |

### Copy mode

| Combo | Action |
|-------|--------|
| `y` | Copy selection to clipboard, clear selection |
| `Escape` | Clear selection, clear search pattern, or exit copy mode |
| `v` / `V` / `Ctrl+v` | Cell / line / block selection |
| `h` `j` `k` `l` | Move |
| `w` `b` `e` | Word motion |
| `0` `$` `^` | Line positions |
| `g` / `G` | Top / bottom of scrollback |
| `H` `M` `L` | Viewport top / middle / bottom |
| `Ctrl+b` / `Ctrl+f` | Page up / down |
| `Ctrl+u` / `Ctrl+d` | Half page up / down |
| `/` / `?` | Search forward / backward (tmux-style `n` / `N` for next/prior match) |

Search mode while editing pattern: `Enter` accepts; `Escape` clears pattern.

## Projects

Project definitions live in **`~/.config/wezterm/projects/*.lua`** (see `M.projects_dir` in `lua/projects.lua`). Each file returns a table:

- **`workspace`** (string, required) — WezTerm workspace name.
- **`cwd`** (string, optional) — Directory; `~` is expanded.
- **`tabs`** (optional list) — After switching/spawning the workspace, extra tabs run optional `cmd` in order; first tab uses the active tab and can `cd` to `cwd`.

Example (`projects/dotfiles.lua`):

```lua
return {
  workspace = "dotfiles",
  cwd = "~/github/meaganewaller/.dotfiles",
  tabs = {
    { cmd = "nvim" },
    { cmd = "claude" },
    { cmd = nil },
  },
}
```

**`leader` + `f`** opens a fuzzy **InputSelector**: configured projects plus any already-active workspaces (“ad-hoc”). Starting a project spawns or switches workspace and, if `tabs` is set, runs the tab commands after a short delay.

## Agent Deck

The config tries to load the **[wezterm-agent-deck](https://github.com/Eric162/wezterm-agent-deck)** plugin. It shows **working / waiting / idle / inactive** state on tab titles (when relevant) and counts **waiting** agents in the right status area.

- **Supported agent types** (for tab/status filtering): OpenCode, Claude, Gemini, Codex, Aider.
- If the plugin fails to load or apply, **fallback detection** uses foreground process heuristics (e.g. OpenCode) and **screen text patterns** in `lua/agent/detection.lua` (waiting / working prompts).
- **Attention notifications:** when the plugin fires `agent_deck.attention_needed`, the config can toast or fall back to `notify-send` (Linux) or `terminal-notifier` / AppleScript (macOS). Plugin-internal notifications are disabled in favor of this wiring.

**Debug:** set `WEZTERM_AGENT_DECK_NOTIFY_DEBUG=1` to log notification paths in WezTerm logs.

## Theme and visuals

- **Color scheme:** `zenwritten_dark` with tab bar colors overridden from `lua/theme.lua`.
- **Background:** Base fill plus **`scanlines.png`** tiled at low opacity.
- **Tab bar:** Bottom, non-fancy bar; titles show `[index]` and truncated pane title; agent icons when state is shown.
- **macOS:** Window background blur and opacity from `platform.lua`; first window maximized on startup (`layout.lua`).

## Platform notes

| Platform | Notes |
|----------|--------|
| **macOS** | Blur, opacity, font size 13, maximize on launch. |
| **Linux (normal)** | Opacity 0.96, often undecorated window. |
| **Linux (VirtualBox)** | Detected via DMI/modules; lower FPS, no transparency, undecorated, smaller font. |
| **Windows** | Default domain `WSL:Ubuntu`, title bar decorations, font size 12; unix domain and custom status events used on Unix only (`mux.lua` / `status.lua`). |

## Changing behavior safely

- **Leader key:** edit `config.leader` in `wezterm.lua`.
- **Colors:** prefer `lua/theme.lua` and `lua/colors.lua` so tabs and Agent Deck stay aligned.
- **New keybindings:** add to `lua/keys.lua` and append rows to the tables in this README if you keep it as documentation.

## References

- [WezTerm docs](https://wezterm.org/)
- [Workspaces recipe](https://wezterm.org/recipes/workspaces.html)
