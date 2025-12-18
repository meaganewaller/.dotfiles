-- keys.lua
local wezterm = require("wezterm")
local act = wezterm.action
local util = require("util")
local commands = require("commands")

local M = {}

-- -------- DSL core --------

local function CB(fn)
  return wezterm.action_callback(fn)
end

local function K(key, mods, action)
  return { key = key, mods = mods, action = action }
end

local function keyspec(spec)
  -- spec can be:
  --   { "k", "CMD", act.Whatever(...) }
  --   { key="k", mods="CMD", action=... }
  if spec.key then
    return spec
  end
  return K(spec[1], spec[2], spec[3])
end

local function bindings(list)
  local out = {}
  for _, spec in ipairs(list) do
    table.insert(out, keyspec(spec))
  end
  return out
end

-- -------- shared helpers (kill duplication) --------

local DIR = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function hjkl_map(mods, mk_action)
  local out = {}
  for key, dir in pairs(DIR) do
    table.insert(out, K(key, mods, mk_action(dir)))
  end
  return out
end

local function concat(a, b)
  for _, v in ipairs(b) do
    table.insert(a, v)
  end
  return a
end

local function mode(name, one_shot)
  return act.ActivateKeyTable({ name = name, one_shot = one_shot ~= false })
end

local function send(text)
  return act.SendString(text)
end

local function tab(name, cmds)
  return CB(function(window, pane)
    util.toggleTabWithCmd(window, pane, name, cmds)
  end)
end

local function leader(key, mods, timeout_ms)
  return { key = key, mods = mods, timeout_milliseconds = timeout_ms or 3000 }
end

-- -------- exported DSL-ish surface --------

M.bindings = bindings
M.K = K
M.CB = CB
M.mode = mode
M.send = send
M.tab = tab

function M.hjkl_nav(mods)
  return hjkl_map(mods, function(dir)
    return act.ActivatePaneDirection(dir)
  end)
end

function M.hjkl_resize(step, mods)
  step = step or 1
  mods = mods or nil
  return hjkl_map(mods, function(dir)
    return act.AdjustPaneSize({ dir, step })
  end)
end

-- “key table builder”
function M.table(name, list)
  return { name = name, keys = bindings(list) }
end

-- -------- apply to wezterm config --------

function M.apply(config)
  config.leader = leader("a", "CTRL", 3000)

  -- Main keybindings (reads like config now)
  config.keys = bindings({
    -- smart ctrl-c copy
    {
      "c",
      "CTRL",
      CB(function(window, pane)
        local has_selection = window:get_selection_text_for_pane(pane) ~= ""
        if has_selection then
          window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
          window:perform_action("ClearSelection", pane)
        else
          window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
        end
      end),
    },

    { "v", "CTRL", act.PasteFrom("Clipboard") },

    -- debug overlay
    { "i", "CMD|SHIFT", act.ShowDebugOverlay },

    -- tabs
    { "t", "CMD", CB(function(window, pane)
      util.createTab(window, pane)
    end) },
    { "b", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
    { "o", "CMD", act.ActivateLastTab },
    { "h", "CMD", act.ActivateTabRelative(-1) },
    { "l", "CMD", act.ActivateTabRelative(1) },
    { "h", "CMD|SHIFT", act.MoveTabRelative(-1) },
    { "l", "CMD|SHIFT", act.MoveTabRelative(1) },
    { "x", "CMD", act.CloseCurrentTab({ confirm = false }) },

    -- rename tab
    {
      "n",
      "CMD",
      act.PromptInputLine({
        description = "Enter new name for tab",
        action = CB(function(window, pane, line)
          if line then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },

    -- panes mode
    { "s", "CMD", mode("splits", true) },

    -- pane nav (deduped)
    -- ALT + hjkl
    -- (spliced in below)

    -- workspaces mode
    { "w", "CMD", mode("workspaces", true) },

    -- fuzzy launchers
    { "a", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|COMMANDS" }) },
    { "d", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

    -- tools
    { "k", "CMD", tab("lazygit", { "lazygit" }) },
    { "u", "CMD", tab("scratch", { "nvim ~/scratchpad.md" }) },
    { "i", "CMD", CB(function(window, pane)
      util.openScrollbackInVIM(window, pane)
    end) },

    -- open links
    {
      "e",
      "CMD",
      act.QuickSelectArgs({
        label = "open",
        patterns = { "https?://\\S+" },
        action = CB(function(win, pane)
          local url = win:get_selection_text_for_pane(pane)
          wezterm.open_with(url)
        end),
      }),
    },

    { "y", "CMD", act.ActivateCommandPalette },

    -- run selected command
    {
      "r",
      "CMD",
      act.InputSelector({
        fuzzy = true,
        title = "Select a command to run",
        choices = commands.get_choices(),
        action = CB(function(window, pane, id, label)
          if id and label then
            commands.invoke_cb(window, pane, id)
          end
        end),
      }),
    },
    {
      "k",
      "CMD|SHIFT",
      wezterm.action_callback(function(window, pane)
        util.show_keymap(window, pane, "WezTerm – Keymaps", {
          "Tabs:     CMD+t new tab | CMD+h/l prev/next | CMD+SHIFT+h/l move | CMD+x close | CMD+n rename",
          "Panes:    ALT+h/j/k/l move focus | CMD+s splits mode | (in splits) v vertical | s horizontal | c close",
          "Resize:   (in splits) R resize mode | hjkl resize | Esc exit",
          "WS:       CMD+w workspace mode | n new | r rename | o picker | j/k next/prev",
          "Tools:    CMD+k lazygit | CMD+u scratch | CMD+i open scrollback in editor",
          "Launcher: CMD+r run command | CMD+a commands | CMD+d workspaces",
        })
      end),
    },
  })

  -- splice in the shared hjkl nav bindings
  concat(config.keys, M.hjkl_nav("ALT"))

  -- Key tables (also declarative + deduped)
  local tables = {
    M.table("splits", {
      { "v", nil, act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
      { "s", nil, act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
      { "r", nil, act.RotatePanes("Clockwise") },
      { "c", nil, act.CloseCurrentPane({ confirm = false }) },

      -- hjkl move (shared)
      -- (spliced in below)

      -- resize mode (stay in it)
      { "R", nil, mode("resize_pane", false) }, -- capital R (so r stays rotate)
      -- if you want r for resize, swap the rotate key or remove rotate
    }),

    M.table("resize_pane", {
      -- shared hjkl resize (step=1)
      -- (spliced in below)
      { "Escape", nil, "PopKeyTable" },
    }),

    M.table("workspaces", {
      {
        "n",
        nil,
        act.PromptInputLine({
          description = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Foreground = { AnsiColor = "Fuchsia" } },
            { Text = "Enter name for new workspace" },
          }),
          action = CB(function(window, pane, line)
            if line then
              window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
            end
          end),
        }),
      },

      {
        "r",
        nil,
        act.PromptInputLine({
          description = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Foreground = { AnsiColor = "Fuchsia" } },
            { Text = "Enter new name for current workspace" },
          }),
          action = CB(function(window, pane, line)
            if line then
              wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
            end
          end),
        }),
      },

      { "o", nil, act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
      { "j", nil, act.SwitchWorkspaceRelative(1) },
      { "k", nil, act.SwitchWorkspaceRelative(-1) },
    }),
  }

  -- build config.key_tables
  config.key_tables = {}

  -- splice shared hjkl move into "splits"
  for _, t in ipairs(tables) do
    if t.name == "splits" then
      concat(t.keys, M.hjkl_nav(nil)) -- no mods inside table
    end
    if t.name == "resize_pane" then
      concat(t.keys, M.hjkl_resize(1, nil))
    end
    config.key_tables[t.name] = t.keys
  end
end

return M
