local Config = require("config.init")

local colors = require("config.colors")
local ui = require("config.ui")
local settings = require("config.settings")
local keys = require("keys.tables")
local mappings = require("keys.bindings")
local tab_bar = require("config.tab-bar")

return Config.tbl_deep_extend("force", {}, colors, ui, settings, keys, mappings, tab_bar)

