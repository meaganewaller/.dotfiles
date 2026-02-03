-- settings.lua
local wezterm = require("wezterm")
local theme = require("theme")

local M = {}

function M.apply(config)
  config.font = wezterm.font_with_fallback({
    { family = "0xProto Nerd Font" },
    { family = "Symbols Nerd Font Mono" },
  })
  config.font_size = 15
  config.line_height = 1.4
  config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"

  -- Get current theme info
  local current = theme.current()
  local mode = current.mode or "dark"
  local accent = (current.accent or {}).hex or "#E5C07B"

  -- Background color based on mode
  local bg_color = mode == "light" and "#FAFAF9" or "#1A1D24"

  config.background = {
    {
      source = { Color = bg_color },
      width = "100%",
      height = "100%",
      opacity = 1,
    },
    {
      hsb = { brightness = mode == "light" and 1 or 0.3 },
      source = {
        File = wezterm.config_dir .. "/wallpapers/tamagotchi-rainbow-clouds-wallpaper-kawaii-hoshi.jpg",
      },
      opacity = 0.1,
    },
  }

  config.window_frame = { border_bottom_height = "0.5cell" }

  config.window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.5cell",
    bottom = "0.5cell",
  }

  -- Tabs
  config.tab_bar_at_bottom = true
  config.tab_max_width = 32
  config.use_fancy_tab_bar = false
  config.show_new_tab_button_in_tab_bar = false
  config.switch_to_last_active_tab_when_closing_tab = true

  config.scrollback_lines = 100000

  -- Color scheme from current theme
  config.color_scheme = theme.wezterm_scheme()

  -- Dynamic palette based on mode
  local p = theme.palette()
  config.colors = {
    background = p.term_background,
    tab_bar = { background = p.edge_bg },
  }

  config.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }
end

return M
