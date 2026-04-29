# WezTerm Configuration

Modular WezTerm configuration with theme integration, workspace management, and
extensible command launcher.

## Keybindings

Porting familiar tmux keybindings to wezterm, since with wezterm we don't
actually need tmux at all. Really.
[Read about it here](https://wezterm.org/multiplexing.html).

| Tmux Concept | WezTerm Equivalent                                       | Description                                                  |
| ------------ | -------------------------------------------------------- | ------------------------------------------------------------ |
| Session      | [Workspace](https://wezterm.org/recipes/workspaces.html) | Isolated environments for different projects/contexts        |
| Window       | Tab                                                      | Multiple terminal views within a session/workspace           |
| Pane         | Pane                                                     | Split views within a window/tab                              |
| Prefix key   | Leader key                                               | Modifier that activates tmux-style commands (I use `Ctrl+a`) |
| Copy mode    | Copy mode                                                | Text selection and navigation mode with enhanced abilities   |

### Reference

#### Leader Key Basics

| Key Combo         | Info                               |
| ----------------- | ---------------------------------- |
| `leader + leader` | Send the leader key itself         |
| `leader + [`      | Enter copy mode for text selection |

#### Workspace Management

| Key Combo    | Info                           |
| ------------ | ------------------------------ |
| `leader + $` | Rename current workspace       |
| `leader + s` | Interactive workspace switcher |
| `leader + (` | Switch to previous workspace   |
| `leader + )` | Switch to next workspace       |

#### Tab Operations

| Key Combo      | Info                                  |
| -------------- | ------------------------------------- |
| `leader + c`   | Create new tab in current domain      |
| `leader + &`   | Close current tab (with confirmation) |
| `leader + p`   | Switch to previous tab                |
| `leader + n`   | Switch to next tab                    |
| `leader + l`   | Switch to last active tab             |
| `leader + 1-9` | Switch to specific tab by index       |

#### Pane Management

##### Splitting & Navigation

| Key Combo        | Info                           |
| ---------------- | ------------------------------ |
| `leader + %`     | Split pane horizontally        |
| `leader + "`     | Split pane vertically          |
| `leader + {`     | Rotate panes counter-clockwise |
| `leader + }`     | Rotate panes clockwise         |
| `leader + arrow` | Navigate to pane in direction  |
| `leader + q`     | Interactive pane selector      |

##### Resizing & Operations

| Key Combo               | Info                                   |
| ----------------------- | -------------------------------------- |
| `leader + z`            | Zoom/unzoom current pane               |
| `leader + !`            | Move pane to new tab                   |
| `leader + ctrl + arrow` | Resize pane in direction (5 cells)     |
| `leader + x`            | Close current pane (with confirmation) |

#### Copy Mode (Advanced Text Selection)

##### Navigation

| Key Combo | Info                       |
| --------- | -------------------------- |
| `h/j/k/l` | Basic directional movement |
| `w/b/e`   | Word-based navigation      |
| `0`       | Beginning of line          |
| `$`       | End of line content        |
| `^`       | Start of line content      |
| `g`       | Top of scrollback          |
| `G`       | Bottom of scrollback       |
| `H/M/L`   | Viewport positioning       |

##### Scrolling & Paging

| Key Combo  | Info                  |
| ---------- | --------------------- |
| `ctrl + b` | Page up               |
| `ctrl + f` | Page down             |
| `ctrl + u` | Scroll up half page   |
| `ctrl + d` | Scroll down half page |

##### Search & Selection

| Key Combo   | Info                    |
| ----------- | ----------------------- |
| `/`         | Search forward          |
| `?`         | Search backward         |
| `n`         | Next search result      |
| `N`         | Previous search result  |
| `v`         | Cell selection mode     |
| `shift + v` | Line selection mode     |
| `ctrl + v`  | Block selection mode    |
| `y`         | Copy selection and exit |
| `Escape`    | Clear selection or exit |
