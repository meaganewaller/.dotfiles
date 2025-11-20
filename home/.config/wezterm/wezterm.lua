local Config = require("config.init")

local colors = require("config.colors")
local ui = require("config.ui")
local settings = require("config.settings")
local keys = require("keys.tables")
local mappings = require("keys.bindings")
local tab_bar = require("config.tab-bar")

-- Set up event handlers
local format_tab_title = require("events.format-tab-title")
local format_window_title = require("events.format-window-title")
local update_status = require("events.update-status")
local new_tab_button_click = require("events.new-tab-button-click")

format_tab_title.setup()
format_window_title.setup()
update_status.setup()
new_tab_button_click.setup()

return Config.tbl_deep_extend("force", {}, colors, ui, settings, keys, mappings, tab_bar)
