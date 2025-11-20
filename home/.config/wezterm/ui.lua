local wez = require("wezterm")
local plugin_config = require("plugin_config")
-- local tabline = wez.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local workspace = wez.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local colors = require("colors")
local theme = colors.color_schemes.lavi

local M = {}

M.apply_to_config = function(c)
  local function get_appearance()
    if wez.gui then
      return wez.gui.get_appearance()
    end
    return "Light"
  end

  local function scheme_for_appearance(appearance)
    if appearance:find("Dark") then
      return "hardhacker"
    else
      return "lavi"
    end
  end

	c.color_scheme = scheme_for_appearance(get_appearance())

	for key, value in pairs({
		bg_color = theme.brights[3],
		fg_color = theme.ansi[2],
		font_size = 20,
	}) do
		for _, prefix in pairs({ "command_palette_", "char_select_" }) do
			c[prefix .. key] = value
		end
	end

	c.window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
  c.window_frame = { font = wez.font("SpaceMono Nerd Font"), font_size = 14 }
	c.window_background_image_hsb = {
		brightness = 1,
		saturation = 1,
		hue = 1,
	}
	c.enable_scroll_bar = false
	c.show_new_tab_button_in_tab_bar = false
	c.tab_bar_at_bottom = true
	c.tab_max_width = 24
	c.use_fancy_tab_bar = false
	c.window_decorations = "TITLE | RESIZE"
  c.animation_fps = 60
  c.hide_mouse_cursor_when_typing = true
  c.max_fps = 60
  c.text_blink_ease_in = "EaseIn"
  c.text_blink_ease_out = "EaseOut"
  c.text_blink_rapid_ease_in = "Linear"
  c.text_blink_rapid_ease_out = "Linear"
  c.text_blink_rate = 800
  c.text_blink_rate_rapid = 250
  c.default_cursor_style = "BlinkingUnderline"
  c.cursor_thickness = "2pt"
  c.audible_bell = "Disabled"
  c.visual_bell = {
    fade_in_function = "EaseOut",
    fade_in_duration_ms = 200,
    fade_out_function = "EaseIn",
    fade_out_duration_ms = 200,
  }
  c.colors = {
    visual_bell = "black"
  }
	workspace.get_choices = function(opts)
		return workspace.choices.get_workspace_elements({})
	end
	-- tabline.setup(plugin_config.tabline)
  c.tab_bar_style = {
    new_tab = wez.format({
      { Background = { Color = theme.background } },
      { Text = " " },
      { Background = { Color = theme.background } },
      { Foreground = { Color = theme.ansi[8] } },
      { Text = " + " },
      { Background = { Color = theme.background } },
      { Text = " " },
    }),
    new_tab_hover = wez.format({
      { Background = { Color = theme.background } },
      { Text = " " },
      { Background = { Color = theme.ansi[6] } },
      { Foreground = { Color = theme.brights[8] } },
      { Text = " + " },
      { Background = { Color = theme.background } },
      { Text = " " },
    }),
  }

  local function tab_title(tab_info)
    local title = tab_info.tab_title
    if title and #title > 0 then
      return title
    end
    return tab_info.active_pane.title
  end

  wez.on("format-tab-title", function(tab, _, _, _, hover, max_width)
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

    title = wez.truncate_left(title, max_width - 4)

    title = " " .. title .. " "

    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = wez.nerdfonts.ple_lower_right_triangle },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = title },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = wez.nerdfonts.ple_lower_left_triangle },
    }
  end)

  wez.on("update-status", function(window)
    local left_background = theme.brights[1]
    local left_forground = theme.brights[8]
    if window:leader_is_active() then
      left_background = theme.ansi[2]
    end
    window:set_left_status(wez.format({
      { Background = { Color = left_background } },
      { Foreground = { Color = left_forground } },
      { Text = " ♥ " },
      { Foreground = { Color = left_background } },
      { Background = { Color = theme.background } },
      { Text = wez.nerdfonts.ple_lower_left_triangle },
      { Text = " " },
    }))
  end)
end

return M
