local wezterm = require("wezterm")

local config = {}
local regular_font = "Recursive"
local italic_font = "VictorMono NF"

config.font_size = 20.0

config.font = wezterm.font({
  family = regular_font,
  weight = "Regular",
  harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
})
config.font_rules = {
  {
    italic = true,
    intensity = "Normal",
    font = wezterm.font({ family = italic_font, style = "Italic" }),
  },
  {
    italic = true,
    intensity = "Half",
    font = wezterm.font({
      family = italic_font,
      weight = "DemiBold",
      style = "Italic",
    }),
  },
  {
    italic = true,
    intensity = "Bold",
    font = wezterm.font({
      family = italic_font,
      weight = "Bold",
      style = "Italic",
    }),
  },
}

config.color_scheme = "lavi"

config.enable_scroll_bar = false

-- https://wezfurlong.org/wezterm/config/lua/config/hyperlink_rules.html

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.window_frame = { font = wezterm.font("SpaceMono Nerd Font Mono") }

return config
