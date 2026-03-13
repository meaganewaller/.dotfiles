-- Theme change handler for sketchybar
-- Responds to theme_changed events and reloads the bar

-- Register the theme_changed event
sbar.add("event", "theme_changed")

local theme_handler = sbar.add("item", "theme_handler", {
  drawing = false,
  updates = true,
})

theme_handler:subscribe("theme_changed", function(env)
  -- Reload sketchybar to pick up new colors
  -- The colors.lua module reads from ~/.config/theme/current.json on load
  sbar.exec("sketchybar --reload")
end)
