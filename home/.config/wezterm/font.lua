local wez = require("wezterm")

local regular_font = "Recursive"
local italic_font = "VictorMono NF"

local M = {}
-- The Font rules are being applied here.
M.apply_to_config = function(c)
  c.font = wez.font({
    family = regular_font,
    weight = "Regular",
    harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
  })
  c.font_size = 18
  c.font_rules = {
    {
      intensity = "Normal",
      italic = true,
      font = wez.font({
        family = italic_font,
        weight = "Regular",
        italic = true,
      }),
    },
    {
		  italic = true,
		  intensity = "Half",
		  font = wez.font({
		  	family = italic_font,
		  	weight = "DemiBold",
		  	style = "Italic",
		  }),
    },
	  {
		  italic = true,
		  intensity = "Bold",
		  font = wez.font({
		  	family = italic_font,
		  	weight = "Bold",
		  	style = "Italic",
		  }),
	  },
  }
  c.adjust_window_size_when_changing_font_size = false
  c.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"
  c.anti_alias_custom_block_glyphs = true
  c.underline_position = -3.5
  c.underline_thickness = "0.1cell"
end

return M
