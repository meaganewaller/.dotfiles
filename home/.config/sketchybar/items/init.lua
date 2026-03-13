local settings = require("settings")

require("items.menus")

-- Load workspace manager based on settings
if settings.window_manager == "aerospace" then
  require("items.aerospace")
else
  require("items.spaces")
end

require("items.front_app")
require("items.calendar")
require("items.widgets")
require("items.media")
require("items.theme")
