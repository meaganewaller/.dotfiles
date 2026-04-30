local wezterm = require("wezterm")
local theme = require("lua.theme")
local scanlines_path = wezterm.config_dir .. "/wallpapers/scanlines.png"

local function depending_on_appearance(arg)
  local appearance = wezterm.gui.get_appearance()
  if appearance:find("Dark") then
    return arg.dark
  else
    return arg.list
  end
end

return function(config)
  config.color_scheme = depending_on_appearance({
    dark = "zenwritten_dark",
    light = "Catppuccin Latte",
  })
  config.colors = {
    tab_bar = {
      background = theme.tab_bar.background,
      active_tab = {
        bg_color = theme.tab_bar.active_bg,
        fg_color = theme.tab_bar.active_fg,
        intensity = theme.tab_bar.active_intensity,
      },
      inactive_tab = {
        bg_color = theme.tab_bar.inactive_bg,
        fg_color = theme.tab_bar.inactive_fg,
        intensity = theme.tab_bar.inactive_intensity,
      },
      inactive_tab_hover = {
        bg_color = theme.tab_bar.inactive_bg_hover,
        fg_color = theme.tab_bar.inactive_fg_hover,
      },
    },
  }

  config.background = {
    {
      source = {
        Color = theme.base.bg,
      },
      width = "100%",
      height = "100%",
      opacity = 0.98,
    },
    {
      source = {
        File = scanlines_path,
      },
      width = "1px",
      height = "1cell",
      repeat_x = "Repeat",
      repeat_y = "Repeat",
      opacity = 0.6,
    },
  }
end
