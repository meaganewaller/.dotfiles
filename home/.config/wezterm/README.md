# WezTerm Configuration

Modular WezTerm configuration with theme integration, workspace management, and extensible command launcher.

## Structure

```
wezterm/
├── wezterm.lua              # Entry point
├── settings.lua             # Font, colors, tabs, background
├── theme.lua                # Theme system integration
├── keys.lua                 # Keybindings DSL
├── events.lua               # Tab formatting, status line
├── commands.lua             # Quick command launcher
├── commands.local.lua       # Machine-specific commands (gitignored)
├── util.lua                 # Helper functions
└── wallpapers/              # Background images
```

## Keybindings

### Leader Key

**`Ctrl+a`** (3 second timeout)

The leader key activates key tables for panes and workspaces.

### Tabs

| Key | Action |
|-----|--------|
| `Cmd+t` | New tab (after current) |
| `Cmd+x` | Close current tab |
| `Cmd+h` | Previous tab |
| `Cmd+l` | Next tab |
| `Cmd+Shift+h` | Move tab left |
| `Cmd+Shift+l` | Move tab right |
| `Cmd+o` | Switch to last active tab |
| `Cmd+n` | Rename current tab |
| `Cmd+b` | Fuzzy tab switcher |

### Panes

| Key | Action |
|-----|--------|
| `Alt+h/j/k/l` | Navigate panes (vim-style) |
| `Cmd+s` | Enter **splits mode** |

#### Splits Mode (after `Cmd+s`)

| Key | Action |
|-----|--------|
| `v` | Split vertical (right) |
| `s` | Split horizontal (down) |
| `h/j/k/l` | Navigate panes |
| `r` | Rotate panes |
| `c` | Close current pane |
| `R` | Enter **resize mode** |

#### Resize Mode (after `Cmd+s`, `R`)

| Key | Action |
|-----|--------|
| `h/j/k/l` | Resize pane |
| `Escape` | Exit resize mode |

### Workspaces

| Key | Action |
|-----|--------|
| `Cmd+w` | Enter **workspace mode** |
| `Cmd+d` | Fuzzy workspace switcher |

#### Workspace Mode (after `Cmd+w`)

| Key | Action |
|-----|--------|
| `n` | New workspace (prompts for name) |
| `r` | Rename current workspace |
| `o` | Fuzzy workspace picker |
| `j` | Next workspace |
| `k` | Previous workspace |

### Tools

| Key | Action |
|-----|--------|
| `Cmd+k` | Toggle lazygit tab |
| `Cmd+u` | Toggle scratch pad (nvim ~/scratchpad.md) |
| `Cmd+i` | Open scrollback in editor |
| `Cmd+e` | Quick select and open URLs |

### Launchers

| Key | Action |
|-----|--------|
| `Cmd+r` | Run custom command |
| `Cmd+a` | Command palette |
| `Cmd+y` | WezTerm command palette |

### Copy/Paste

| Key | Action |
|-----|--------|
| `Ctrl+c` | Smart copy (copies selection if present, else sends SIGINT) |
| `Ctrl+v` | Paste from clipboard |

### Debug

| Key | Action |
|-----|--------|
| `Cmd+Shift+i` | Show debug overlay |
| `Cmd+Shift+k` | Show keybinding help |

## Theme Integration

The configuration reads from `~/.config/theme/current.json` for:

- Color scheme selection
- Light/dark mode
- Accent colors for tabs and status bar

The theme changes automatically when you run `theme set <name>` or `theme dark`/`theme light`.

## Custom Commands

### Default Commands

Available out of the box via `Cmd+r`:

- `nvim` - Open Neovim
- `vim-diff` - Open vim in diff mode
- `htop` - System monitor
- `dotfiles` - Open dotfiles directory

### Adding Machine-Specific Commands

Create `~/.config/wezterm/commands.local.lua` (not tracked in git):

```lua
return {
  {
    label = "my-project",
    title = "my-project",
    cwd = "~/projects/my-project",
  },
  {
    label = "dev-server",
    title = "dev",
    cwd = "~/projects/webapp",
    cmds = { "npm run dev" },
  },
}
```

See `commands.local.lua.example` for more examples including:
- Environment variable expansion (`$WORK_REPO`)
- Complex multi-tab setups with callbacks

## Customization

### Changing Leader Key

Edit `keys.lua`:

```lua
config.leader = leader("a", "CTRL", 3000)  -- key, mods, timeout_ms
```

### Changing Font

Edit `settings.lua`:

```lua
config.font = wezterm.font_with_fallback({
  { family = "Your Font Name" },
  { family = "Symbols Nerd Font Mono" },
})
config.font_size = 15
```

### Changing Background

Edit `settings.lua`, modify the `config.background` table:

```lua
config.background = {
  { source = { Color = bg_color }, ... },
  { source = { File = "path/to/image.jpg" }, opacity = 0.1, ... },
}
```

### Adding New Key Tables

Use the DSL in `keys.lua`:

```lua
M.table("my_mode", {
  { "a", nil, act.SomeAction },
  { "b", nil, act.AnotherAction },
})
```

Then activate with:

```lua
{ "m", "CMD", mode("my_mode", true) }  -- one_shot = true
```

## Troubleshooting

### Commands not loading

Check `commands.local.lua` syntax:

```bash
lua -c "dofile('~/.config/wezterm/commands.local.lua')"
```

### Theme not applying

Ensure theme file exists:

```bash
cat ~/.config/theme/current.json
```

### Keybindings not working

1. Check for conflicts with system shortcuts
2. Use `Cmd+Shift+i` to open debug overlay
3. Use `Cmd+Shift+k` to see keybinding reference

### Fish/zsh not loading as login shell

Check `util.lua` shell detection or set explicitly:

```bash
export WEZTERM_SHELL=/path/to/shell
```
