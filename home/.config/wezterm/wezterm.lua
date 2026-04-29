local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }

require("lua.base")(config)
require("lua.keys").apply_to_config(config)
require("lua.fonts")(config)
require("lua.colors")(config)
require("lua.layout")(config)
require("lua.agent").apply(config)
require("lua.tabs")(config)
require("lua.status")
require("lua.mux")(config)
require("lua.platform")(config)

return config
