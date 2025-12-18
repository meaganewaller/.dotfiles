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

  config.background = {
    {
      source = { Color = "#FAFAF9" },
      width = "100%",
      height = "100%",
      opacity = 1,
    },
    {
      hsb = { brightness = 1 },
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

  config.color_scheme = theme.scheme()

  local p = theme.palette()
  config.colors = {
    background = p.term_background,
    tab_bar = { background = p.edge_bg },
  }

  config.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }
end

return M
