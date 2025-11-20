local wezterm = require("wezterm")
local fn = require("utils.functions")

local act = wezterm.action

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(key)
	return {
		key = key,
		mods = "META",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({ SendKey = { key = key, mods = "META" } }, pane)
			else
				win:perform_action(act.ActivatePaneDirection(direction_keys[key]), pane)
			end
		end),
	}
end

local config = {
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 5000 },
	disable_default_key_bindings = true,
	disable_default_mouse_bindings = true,
}

config.keys = {
	-- Clipboard
	{ key = "c", mods = "META", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "META", action = act.PasteFrom("Clipboard") },

	-- UI
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Wezterm
	{ key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
	{ key = "p", mods = "CTRL|META|SHIFT", action = act.ActivateCommandPalette },

	-- Multiplexing
	{ key = "Return", mods = "CTRL|META", action = act.SpawnTab("CurrentPaneDomain") },

	{ key = "'", mods = "CTRL|META", action = act.ActivateTabRelative(1) },
	{ key = ";", mods = "CTRL|META", action = act.ActivateTabRelative(-1) },
	{ key = '"', mods = "CTRL|META|SHIFT", action = act.MoveTabRelative(1) },
	{ key = ":", mods = "CTRL|META|SHIFT", action = act.MoveTabRelative(-1) },

	{ key = "v", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "Space", mods = "LEADER|CTRL", action = act.PaneSelect },
	{ key = "Space", mods = "CTRL|SHIFT", action = act.PaneSelect },

	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	{ key = "{", mods = "CTRL|META|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "}", mods = "CTRL|META|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "[", mods = "CTRL|META", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "]", mods = "CTRL|META", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Move between split panes
	split_nav("h"),
	split_nav("j"),
	split_nav("k"),
	split_nav("l"),

	-- Switch Tabs
	{ key = "!", mods = "CTRL|SHIFT", action = act.ActivateTab(0) },
	{ key = "@", mods = "CTRL|SHIFT", action = act.ActivateTab(1) },
	{ key = "#", mods = "CTRL|SHIFT", action = act.ActivateTab(2) },
	{ key = "$", mods = "CTRL|SHIFT", action = act.ActivateTab(3) },
	{ key = "%", mods = "CTRL|SHIFT", action = act.ActivateTab(4) },
	{ key = "^", mods = "CTRL|SHIFT", action = act.ActivateTab(5) },
	{ key = "&", mods = "CTRL|SHIFT", action = act.ActivateTab(6) },
	{ key = "*", mods = "CTRL|SHIFT", action = act.ActivateTab(7) },
	{ key = "(", mods = "CTRL|SHIFT", action = act.ActivateTab(8) },
	{ key = ")", mods = "CTRL|SHIFT", action = act.ActivateTab(9) },

	-- Neovim special keys
	{ key = "q", mods = "CTRL|SHIFT", action = fn.send_utf8(0xff01) },
	{ key = "n", mods = "CTRL|SHIFT", action = fn.send_utf8(0xff02) },
	{ key = "q", mods = "CTRL|META", action = fn.send_utf8(0xff03) },
	{ key = "q", mods = "CTRL|META|SHIFT", action = fn.send_utf8(0xff04) },
	{ key = "Backslash", mods = "CTRL", action = fn.send_utf8(0x00f0) },
	{ key = "Backslash", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f1) },
	{ key = "Backslash", mods = "META|SHIFT", action = fn.send_utf8(0x00f2) },
	{ key = "Grave", mods = "CTRL", action = fn.send_utf8(0x00f3) },
	{ key = "w", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f4) },
	{ key = "f", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f5) },
	{ key = "t", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f6) },
	{ key = "a", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f7) },
	{ key = "'", mods = "CTRL", action = fn.send_utf8(0x00f8) },
	{ key = "p", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00f9) },
	{ key = "Period", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00fa) },
	{ key = "Period", mods = "CTRL", action = fn.send_utf8(0x00fb) },
	{ key = "o", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00fc) },
	{ key = "i", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00fd) },
	{ key = "c", mods = "META", action = fn.send_utf8(0x00fe) },
	{ key = "Slash", mods = "CTRL", action = fn.send_utf8(0x00d4) },
	{ key = "Slash", mods = "CTRL|META", action = fn.send_utf8(0x00d5) },
	{ key = "Slash", mods = "CTRL|SHIFT", action = fn.send_utf8(0x00d6) },
	{ key = "Slash", mods = "META|SHIFT", action = fn.send_utf8(0x00d7) },
	{ key = "Slash", mods = "CTRL|META|SHIFT", action = fn.send_utf8(0x00d8) },
	{ key = "Space", mods = "META", action = fn.send_utf8(0x00d9) },

	-- Other special keys
	{ key = "Return", mods = "CTRL", action = fn.send_escape("[24~") },
	{ key = "Return", mods = "META", action = fn.send_escape("[25~") },
	{ key = "Tab", mods = "META|SHIFT", action = fn.send_escape("[23;5~") },
	{ key = "Comma", mods = "CTRL", action = fn.send_escape("[21;5~") },
	{ key = "j", mods = "CTRL|META|SHIFT", action = fn.send_escape("[20;5~") },
	{ key = "k", mods = "CTRL|META|SHIFT", action = fn.send_escape("[19;5~") },
	{ key = "u", mods = "CTRL|META|SHIFT", action = fn.send_escape("[24;2~") },
	{ key = "q", mods = "CTRL|META|SHIFT", action = fn.send_utf8(0xff01) },
	{ key = "n", mods = "CTRL|META|SHIFT", action = fn.send_utf8(0xff02) },
	{ key = "q", mods = "CTRL|META", action = fn.send_utf8(0xff03) },
	{ key = "q", mods = "CTRL|META|SHIFT", action = fn.send_utf8(0xff04) },
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
}

return config
