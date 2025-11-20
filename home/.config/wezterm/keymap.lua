local wezterm = require("wezterm")
local act = wezterm.action
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local utils = require("utils")

local M = {}

M.general = {
    {
        key = "F11",
        mods = "NONE",
        action = act.ToggleFullScreen,
    },
    { key = "Space", mods = "CTRL", action = act.ActivateKeyTable({ name = "tmux", one_shot = true }) },
    { key = "Enter", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[13;5u" }) },
    { key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b[13;2u" }) },
    { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
    { key = "p", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
    { key = "d", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
    { key = "w", mods = "CTRL|SHIFT", action = act.QuitApplication },
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
    { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
    utils.split_nav("move", "h"),
    utils.split_nav("resize", "h"),
    utils.split_nav("move", "j"),
    utils.split_nav("resize", "j"),
    utils.split_nav("move", "k"),
    utils.split_nav("resize", "k"),
    utils.split_nav("move", "l"),
    utils.split_nav("resize", "l"),
}

M.tmux = {
    -- tmux defaults
    { key = "%", mods = "SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = '"', mods = "SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "(", mods = "SHIFT", action = act.SwitchWorkspaceRelative(-1) },
    { key = ")", mods = "SHIFT", action = act.SwitchWorkspaceRelative(1) },
    { key = "&", mods = "SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    {
        key = "!",
        mods = "SHIFT",
        action = wezterm.action_callback(function(win, pane)
            local tab, window = pane:move_to_new_tab()
        end),
    },
    { key = "c", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n", action = act.ActivateTabRelative(1) },
    { key = "p", action = act.ActivateTabRelative(-1) },
    { key = "x", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "z", action = act.TogglePaneZoomState },
    { key = "Space", action = act.RotatePanes("Clockwise") },
    { key = "[", action = act.ActivateCopyMode },
    { key = "s", action = workspace_switcher.switch_workspace() },
    { key = "r", action = act.ReloadConfiguration },
    -- wezterm extras
    { key = "/", action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "q", action = act.QuickSelect },
    {
        key = "i",
        mods = "SHIFT",
        action = wezterm.action_callback(function()
            wezterm.plugin.update_all()
        end),
    },
    {
        key = "w",
        action = wezterm.action.PromptInputLine({
            description = "Enter workspace name",
            action = wezterm.action_callback(function(window, pane, workspace)
                if workspace and #workspace > 0 then
                    window:perform_action(wezterm.action.SwitchToWorkspace({ name = workspace }), pane)
                end
            end),
        }),
    },
    {
        key = "l",
        action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
    },
}

return M
