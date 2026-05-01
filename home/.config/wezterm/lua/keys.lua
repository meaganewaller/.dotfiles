local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local projects = require("plugin.projects")
local commands = require("plugin.commands")
local utils = require("lua.utils")
local cheatsheet = require("plugin.cheatsheet")
local theme = require("lua.theme")

local M = {}

local function CB(fn)
  return wezterm.action_callback(fn)
end

local function K(key, mods, action)
  return { key = key, mods = mods, action = action }
end

local function keyspec(spec)
  -- spec can be:
  -- { "k", "CMD", act.Whatever(...) }
  -- { key="k", mods="CMD", action=act.Whatever(...) }
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
    utils.tabs.toggle_tab_with_cmd(window, pane, name, cmds)
  end)
end

local function leader(key, mods, timeout_ms)
  return { key = key, mods = mods, timeout_milliseconds = timeout_ms or 3000 }
end

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

M.actions = {
  RenameWorkspace = wezterm.action_callback(function(window, pane)
    window:perform_action(
      act.PromptInputLine({
        description = "Rename workspace: ",
        action = wezterm.action_callback(function(_, _, line)
          if not line or line == "" then
            return
          end

          mux.rename_workspace(mux.get_active_workspace(), line)
        end),
      }),
      pane
    )
  end),

  RenameCurrentTab = act.PromptInputLine({
    description = "Enter new name for tab: ",
    action = CB(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  }),
}

function M.apply_to_config(config)
  if not config.leader then
    config.leader = leader("a", "CTRL", 3000)
    wezterm.log_warn("No leader key set, using default: Ctrl-a")
  end

  -- Main keybindings (reads like config now)
  config.keys = bindings({
    -- Smart CTRL-C Copy
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

    -- Debug overlay
    { "i", "CMD|SHIFT", act.ShowDebugOverlay },

    -- Workspaces
    { "$", "LEADER|SHIFT", M.actions.RenameWorkspace },
    { "s", "LEADER", projects.picker_action() },
    { "(", "LEADER|SHIFT", act.SwitchWorkspaceRelative(-1) },
    { ")", "LEADER|SHIFT", act.SwitchWorkspaceRelative(1) },

    -- Tabs
    { "c", "LEADER", act.SpawnTab("CurrentPaneDomain") },
    { "&", "LEADER|SHIFT", act.CloseCurrentTab({ confirm = true }) },
    { "p", "LEADER", act.ActivateTabRelative(-1) },
    { "n", "LEADER", act.ActivateTabRelative(2) },
    { "b", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
    { "l", "LEADER", act.ActivateLastTab },
    { "h", "CMD|SHIFT", act.MoveTabRelative(-1) },
    { "l", "CMD|SHIFT", act.MoveTabRelative(1) },
    { "x", "CMD", act.CloseCurrentTab({ confirm = false }) },
    { ",", "LEADER", M.actions.RenameCurrentTab },
    { "w", "LEADER", act.ShowTabNavigator },

    -- Panes
    { "%", "LEADER|SHIFT", act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { '"', "LEADER|SHIFT", act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { "{", "LEADER|SHIFT", act.RotatePanes("CounterClockwise") },
    { "}", "LEADER|SHIFT", act.RotatePanes("Clockwise") },
    { "LeftArrow", "LEADER", act.ActivatePaneDirection("Left") },
    { "DownArrow", "LEADER", act.ActivatePaneDirection("Down") },
    { "UpArrow", "LEADER", act.ActivatePaneDirection("Up") },
    { "RightArrow", "LEADER", act.ActivatePaneDirection("Right") },
    { "q", "LEADER", act.PaneSelect({ mode = "Activate" }) },
    -- { "z", "LEADER", act.TogglePaneZoomState },
    -- { "!", "LEADER|SHIFT", act.MovePaneToNewTab },
    { "LeftArrow", "LEADER|CTRL", act.AdjustPaneSize({ "Left", 5 }) },
    { "DownArrow", "LEADER|CTRL", act.AdjustPaneSize({ "Down", 5 }) },
    { "UpArrow", "LEADER|CTRL", act.AdjustPaneSize({ "Up", 5 }) },
    { "RightArrow", "LEADER|CTRL", act.AdjustPaneSize({ "Right", 5 }) },
    { "x", "LEADER", act.CloseCurrentPane({ confirm = true }) },

    { " ", "LEADER", act.QuickSelect },

    -- panes mode
    { "s", "CMD", mode("splits", true) },

    -- workspaces mode
    { "w", "CMD", mode("workspaces", true) },

    -- fuzzy launchers
    { "a", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|COMMANDS" }) },
    { "d", "CMD", act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    { "p", "CMD", projects.picker_action() },

    -- tools
    { "k", "CMD", tab("lazygit", { "lazygit" }) },
    { "u", "CMD", tab("scratch", { "nvim ~/scratchpad.md" }) },
    { 
      "i", 
      "CMD", 
      CB(function(window, pane)
        utils.open_scrollback_in_vim(window, pane)
      end),
    },

    -- Open Links
    {
      "e",
      "CMD",
      act.QuickSelectArgs({
        label = "Open Link",
        patterns = { "https?://[^ ]+" },
        action = CB(function(window, pane)
          local url = window:get_selection_text_for_pane(pane)
          wezterm.open_with(url)
        end),
      }),
    },

    { "y", "CMD", act.ActivateCommandPalette },

    -- Run Selected Command
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

    -- Keybinding Help
    { "k", "LEADER", cheatsheet.quick_lookup_action() },

    -- Copy Mode
    { "[", "LEADER", act.ActivateCopyMode },

    { "f", "LEADER", projects.picker_action() },

    { "d", "LEADER", act.QuitApplication }, -- detach (quit)
    { ":", "LEADER|SHIFT", act.ActivateCommandPalette },
    { "r", "LEADER", act.ReloadConfiguration }, -- reload config
  })

  concat(config.keys, M.hjkl_nav("ALT"))

  local tables = {
    M.table("splits", {
      { "v", nil, act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
      { "s", nil, act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
      { "r", nil, act.RotatePanes("Clockwise") },
      { "c", nil, act.CloseCurrentPane({ confirm = false }) },

      { "R", nil, mode("resize_pane", false) }, -- Capital R (so r stays rotate)
    }),

    M.table("resize_pane", {
      { "Escape", nil, "PopKeyTable" },
    }),

    M.table("workspaces", {
      {
        "n",
        nil,
        act.PromptInputLine({
          description = wezterm.format({
            { Attribute = { Intensity = "Bold" } },
            { Foreground = { Color = theme.palette_from_config(config).tab.active_fg }},
            { Text = "Enter name for new workspace: " },
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
            { Foreground = { Color = theme.palette_from_config(config).tab.active_fg }},
            { Text = "Enter new name for current workspace: " },
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

-- local search_direction = {
--   BACKWARD = 0,
--   FORWARD = 1,
-- }

-- wezterm.GLOBAL.tmux_search_directions = {}

-- M.action = {
--   ClearPattern = wezterm.action_callback(function(window, pane)
--     wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
--     window:perform_action(
--       act.Multiple({
--         act.CopyMode("ClearPattern"),
--         act.CopyMode("AcceptPattern"),
--       }),
--       pane
--     )
--   end),

--   ClearSelectionOrClearPatternOrClose = wezterm.action_callback(function(window, pane)
--     local action

--     if window:get_selection_text_for_pane(pane) ~= "" then
--       action = act.Multiple({
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       })
--     elseif wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
--       action = M.action.ClearPattern
--     else
--       action = act.CopyMode("Close")
--     end

--     window:perform_action(action, pane)
--   end),

--   NextMatch = wezterm.action_callback(function(window, pane)
--     local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
--     local action

--     if not direction then
--       return
--     end

--     if direction == search_direction.BACKWARD then
--       action = act.Multiple({
--         act.CopyMode("PriorMatch"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       })
--     elseif direction == search_direction.FORWARD then
--       action = act.Multiple({
--         act.CopyMode("NextMatch"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       })
--     end

--     window:perform_action(action, pane)
--   end),

--   PriorMatch = wezterm.action_callback(function(window, pane)
--     local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
--     local action

--     if not direction then
--       return
--     end

--     if direction == search_direction.BACKWARD then
--       action = act.Multiple({
--         act.CopyMode("NextMatch"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       })
--     elseif direction == search_direction.FORWARD then
--       action = act.Multiple({
--         act.CopyMode("PriorMatch"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       })
--     end

--     window:perform_action(action, pane)
--   end),

--   MovePaneToNewTab = wezterm.action_callback(function(_, pane)
--     local tab, _ = pane:move_to_new_tab()
--     tab:activate()
--   end),

--     wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = search_direction.BACKWARD

--     window:perform_action(
--       act.Multiple({
--         act.CopyMode("ClearPattern"),
--         act.CopyMode("EditPattern"),
--       }),
--       pane
--     )
--   end),

--   SearchForward = wezterm.action_callback(function(window, pane)
--     wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = search_direction.FORWARD

--     window:perform_action(
--       act.Multiple({
--         act.CopyMode("ClearPattern"),
--         act.CopyMode("EditPattern"),
--       }),
--       pane
--     )
--   end),

--   WorkspaceSelect = wezterm.action_callback(function(window, pane)
--     local active_workspace = mux.get_active_workspace()
--     local workspaces = mux.get_workspace_names()
--     local num_tabs_by_workspace = {}

--     for _, mux_window in ipairs(mux.all_windows()) do
--       local workspace = mux_window:get_workspace()
--       local num_tabs = #mux_window:tabs()

--       if num_tabs_by_workspace[workspace] then
--         num_tabs_by_workspace[workspace] = num_tabs_by_workspace[workspace] + num_tabs
--       else
--         num_tabs_by_workspace[workspace] = num_tabs
--       end
--     end

--     local choices = {
--       {
--         id = active_workspace,
--         label = active_workspace .. ": " .. num_tabs_by_workspace[active_workspace] .. " tabs (active)",
--       },
--     }

--     for _, workspace in ipairs(workspaces) do
--       if workspace ~= active_workspace then
--         table.insert(choices, {
--           id = workspace,
--           label = workspace .. ": " .. num_tabs_by_workspace[workspace] .. " tabs",
--         })
--       end
--     end

--     window:perform_action(
--       act.InputSelector({
--         title = "Select Workspace",
--         choices = choices,
--         action = wezterm.action_callback(function(_, _, id, _)
--           if not id then
--             return
--           end

--           mux.set_active_workspace(id)
--         end),
--       }),
--       pane
--     )
--   end),

--   RenameCurrentTab = wezterm.action_callback(function(win, pane)
--     win:perform_action(
--       act.PromptInputLine({
--         description = "Enter new name for tab",
--         action = wezterm.action_callback(function(_, _, line)
--           if not line or line == "" then
--             return
--           end
--           win:active_tab():set_title(line)
--         end),
--       }),
--       pane
--     )
--   end),
-- }

-- function M.apply_to_config(config, _)
--   if not config.leader then
--     config.leader = { key = "a", mods = "CTRL" }
--     wezterm.log_warn("No leader key set, using default: Ctrl-a")
--   end

--   local keys = {
--     {
--       key = config.leader.key,
--       mods = "LEADER|" .. config.leader.mods,
--       action = act.SendKey({ key = config.leader.key, mods = config.leader.mods }),
--     },

--     {
--       key = "Enter",
--       mods = "SHIFT",
--       action = act.SendKey({ key = "Enter", mods = "ALT" }),
--     },

--     -- Workspaces
--     { key = "$", mods = "LEADER|SHIFT", action = M.action.RenameWorkspace },
--     { key = "s", mods = "LEADER", action = M.action.WorkspaceSelect },
--     { key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
--     { key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },

--     -- Tabs
--     { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
--     {
--       key = "&",
--       mods = "LEADER|SHIFT",
--       action = act.CloseCurrentTab({ confirm = true }),
--     },
--     { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
--     { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
--     { key = "l", mods = "LEADER", action = act.ActivateLastTab },
--     { key = ",", mods = "LEADER", action = M.action.RenameCurrentTab },
--     { key = "w", mods = "LEADER", action = act.ShowTabNavigator },

--     -- Panes
--     {
--       key = "%",
--       mods = "LEADER|SHIFT",
--       action = act.SplitHorizontal({
--         domain = "CurrentPaneDomain",
--       }),
--     },
--     {
--       key = '"',
--       mods = "LEADER|SHIFT",
--       action = act.SplitVertical({
--         domain = "CurrentPaneDomain",
--       }),
--     },
--     { key = "{", mods = "LEADER|SHIFT", action = act.RotatePanes("CounterClockwise") },
--     { key = "}", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise") },
--     { key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
--     { key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
--     { key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
--     { key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
--     { key = "q", mods = "LEADER", action = act.PaneSelect({ mode = "Activate" }) },
--     { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
--     { key = "!", mods = "LEADER|SHIFT", action = M.action.MovePaneToNewTab },
--     { key = "LeftArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Left", 5 }) },
--     { key = "DownArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Down", 5 }) },
--     { key = "UpArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Up", 5 }) },
--     { key = "RightArrow", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Right", 5 }) },
--     { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

--     { key = " ", mods = "LEADER", action = act.QuickSelect },

--     -- Copy Mode
--     { key = "[", mods = "LEADER", action = act.ActivateCopyMode },

--     {
--       key = "f",
--       mods = "LEADER",
--       action = projects.picker_action(),
--     },

--     { key = "d", mods = "LEADER", action = act.QuitApplication }, -- detach (quit)
--     { key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
--     { key = "r", mods = "LEADER", action = act.ReloadConfiguration }, -- reload config
--   }

--   local index_offset = config.tab_and_split_indices_are_zero_based and 0 or 1
--   for i = index_offset, 9 do
--     table.insert(keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - index_offset) })
--   end

--   local copy_mode = {
--     {
--       key = "y",
--       mods = "NONE",
--       action = act.Multiple({
--         act.CopyTo("Clipboard"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       }),
--     },
--     { key = "Escape", mods = "NONE", action = M.action.ClearSelectionOrClearPatternOrClose },
--     { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
--     { key = "v", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
--     { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
--     { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
--     { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
--     { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
--     { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
--     { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
--     { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
--     { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
--     { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
--     { key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
--     { key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
--     { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
--     { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
--     { key = "h", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
--     { key = "m", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
--     { key = "l", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
--     { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
--     { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
--     { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
--     { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },

--     { key = "/", mods = "NONE", action = M.action.SearchForward },
--     { key = "?", mods = "SHIFT", action = M.action.SearchBackward },
--     { key = "n", mods = "NONE", action = M.action.NextMatch },
--     { key = "N", mods = "NONE", action = M.action.PriorMatch },
--   }

--   local search_mode = {
--     {
--       key = "Enter",
--       action = act.Multiple({
--         act.CopyMode("AcceptPattern"),
--         act.ClearSelection,
--         act.CopyMode("ClearSelectionMode"),
--       }),
--     },
--     { key = "Escape", action = M.action.ClearPattern },
--   }

--   if not config.keys then
--     config.keys = {}
--   end
--   for _, key in ipairs(keys) do
--     table.insert(config.keys, key)
--   end

--   if not config.key_tables then
--     config.key_tables = {}
--   end

--   if not config.key_tables.copy_mode then
--     config.key_tables.copy_mode = {}
--   end
--   for _, key in ipairs(copy_mode) do
--     table.insert(config.key_tables.copy_mode, key)
--   end

--   if not config.key_tables.search_mode then
--     config.key_tables.search_mode = {}
--   end
--   for _, key in ipairs(search_mode) do
--     table.insert(config.key_tables.search_mode, key)
--   end
-- end

return M
