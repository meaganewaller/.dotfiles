local M = {}

M.base = {
  bg = "#191919",
  fg = "#bbbbbb",
  fg_active = "#b7b7b7",
  fg_muted = "#636363",
  separator = "#515151",
  hl_1 = "#ffb7ff",
}

M.tab_bar = {
  background = "none",
  active_fg = "#826AED",
  active_bg = "#253031",
  active_intensity = "Bold",
  inactive_bg = "none",
  inactive_fg = "#ffb7ff",
  inactive_bg_hover = "#ffb7ff",
  inactive_fg_hover = "#32292f",
  inactive_intensity = "Half",
  -- Tab titles (powerline-style separators need a Nerd/patched font)
  max_width = 32,
  powerline = {
    rounded_left = utf8.char(0xe0b6),
    rounded_right = utf8.char(0xe0b4),
  },
}

M.agent = {
  working = "#8f9a72",
  waiting = "#c49f6f",
  idle = "#7f9b99",
  inactive = "#636363",
}

M.workhours = {
  start_fg = "#999999",
  half_fg = "#b77e64",
  end_fg = "#d2af0d",
  good_fg = "#819b69",
  over_fg = "#d79999",
}

return M
