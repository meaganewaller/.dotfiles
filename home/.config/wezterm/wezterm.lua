---@type Wezterm
local wezterm = require("wezterm")

local config = wezterm.config_builder()

require("settings").apply(config)
require("keys").apply(config)
require("events").register(config)

local util = require("util")
config.default_prog = util.shell_args(true)

return config
