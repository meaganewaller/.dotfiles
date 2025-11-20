local wezterm = require("wezterm")
local colors = require("config.colors")
local ui = require("config.ui")

local nf = wezterm.nerdfonts

local config = {}

local theme = colors.color_schemes[ui.color_scheme]

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

function tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
	local edge_background = theme.background
	local background = theme.light_background
	local foreground = theme.ansi[8]

	if tab.is_active then
		background = theme.brights[1]
		foreground = theme.brights[8]
	elseif hover then
		foreground = theme.brights[8]
	end

	local edge_foreground = background

	local title = tab_title(tab)

	title = wezterm.truncate_left(title, max_width - 4)

	title = " " .. title .. " "

	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = nf.ple_lower_right_triangle },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = nf.ple_lower_left_triangle },
	}
end)

wezterm.on("update-status", function(window)
	local left_background = theme.brights[1]
	local left_forground = theme.brights[8]
	if window:leader_is_active() then
		left_background = theme.ansi[2]
	end
	window:set_left_status(wezterm.format({
		{ Background = { Color = left_background } },
		{ Foreground = { Color = left_forground } },
		{ Text = " ♥ " },
		{ Foreground = { Color = left_background } },
		{ Background = { Color = theme.background } },
		{ Text = nf.ple_lower_left_triangle },
		{ Text = " " },
	}))
end)

return config
