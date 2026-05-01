local wezterm = require("wezterm")
local mux = wezterm.mux
local path_utils = require("lua.utils.path")

return function(config)
  config.window_decorations = "RESIZE|MACOS_FORCE_DISABLE_SHADOW"
  config.window_padding = {
    left = "1cell",
    right = "1cell",
    top = ".5cell",
    bottom = 0,
  }

  if path_utils.is_macos then
    -- maximize first window
    wezterm.on("gui-startup", function(cmd)
      local _, _, window = mux.spawn_window(cmd or {})
      window:gui_window():maximize()
    end)
  end
end
