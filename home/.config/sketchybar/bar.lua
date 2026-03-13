local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  position = "top",
  height = 40,
  color = colors.bar.bg,
  blur_radius = 50,
  margin = 10,
  corner_radius = 6,
  y_offset = 6,
  padding_right = 10,
  padding_left = 10,
  border_width = 0,
})
