local wezterm = require("wezterm")
local colors = require("config.colors")
local ui = require("config.ui")

local config = {}

local theme = colors.color_schemes[ui.color_scheme]
local nf = wezterm.nerdfonts

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 24

config.tab_bar_style = {
	new_tab = wezterm.format({
		{ Background = { Color = theme.background } },
		{ Text = " " },
		{ Background = { Color = theme.background } },
		{ Foreground = { Color = theme.ansi[8] } },
		{ Text = " + " },
		{ Background = { Color = theme.background } },
		{ Text = " " },
	}),
	new_tab_hover = wezterm.format({
		{ Background = { Color = theme.background } },
		{ Text = " " },
		{ Background = { Color = theme.ansi[6] } },
		{ Foreground = { Color = theme.brights[8] } },
		{ Text = " + " },
		{ Background = { Color = theme.background } },
		{ Text = " " },
	}),
}

-- Event handlers are set up in events/format-tab-title.lua and events/update-status.lua

return config
