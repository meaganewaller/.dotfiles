local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
-- Matches original sketchybarrc styling
sbar.default({
  updates = "on",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 17.0,
    },
    color = colors.subtext,
    padding_left = 2,
    padding_right = 5,
    background = { image = { corner_radius = 9 } },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    color = colors.text,
    padding_left = 2,
    padding_right = 2,
  },
  background = {
    height = 28,
    corner_radius = 9,
    border_width = 0,
    border_color = colors.border,
    padding_left = 5,
    padding_right = 5,
    image = {
      corner_radius = 9,
      border_color = colors.grey,
      border_width = 1,
    },
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 9,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 50,
  },
  padding_left = 5,
  padding_right = 5,
  scroll_texts = true,
})
