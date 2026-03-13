-- Aerospace workspace integration for sketchybar
-- Replaces yabai-based spaces with aerospace workspaces

local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Register the aerospace workspace change event
sbar.add("event", "aerospace_workspace_change")

-- Helper to determine which display a workspace should appear on
local function get_display_for_workspace(sid)
  local id = tonumber(sid)
  if id >= 8 and id <= 10 then
    return 3
  elseif id >= 11 then
    return 2
  else
    return 1
  end
end

-- Helper to get app icons for a workspace
local function get_workspace_icons(sid, callback)
  sbar.exec("aerospace list-windows --workspace " .. sid .. " 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, \"\", $2); print $2}'", function(apps)
    local icon_strip = ""
    if apps and apps ~= "" then
      for app in apps:gmatch("[^\r\n]+") do
        local lookup = app_icons[app]
        local icon = lookup or app_icons["Default"] or "?"
        icon_strip = icon_strip .. " " .. icon
      end
    end
    callback(icon_strip)
  end)
end

-- Create workspace items
local workspaces = {}

-- Get all workspaces from aerospace
sbar.exec("aerospace list-workspaces --all 2>/dev/null", function(result)
  if not result or result == "" then
    -- Fallback: create workspaces 1-10
    for i = 1, 10 do
      table.insert(workspaces, tostring(i))
    end
  else
    for ws in result:gmatch("[^\r\n]+") do
      table.insert(workspaces, ws)
    end
  end

  -- Create items for each workspace
  for _, sid in ipairs(workspaces) do
    local display_id = get_display_for_workspace(sid)

    local space = sbar.add("item", "space." .. sid, {
      display = display_id,
      icon = {
        string = sid,
        color = colors.accent,
        padding_left = 10,
        font = {
          family = settings.font.numbers,
          style = settings.font.style_map["Bold"],
          size = 14.0,
        },
        shadow = { distance = 4 },
      },
      label = {
        font = "sketchybar-app-font:Regular:16.0",
        padding_right = 20,
        padding_left = 0,
        y_offset = -1,
        shadow = { drawing = false },
      },
      background = {
        color = colors.item_bg,
        corner_radius = 5,
        drawing = true,
        border_color = colors.pastel.green,
        border_width = 0,
        height = 25,
      },
      click_script = "aerospace workspace " .. sid,
    })

    -- Subscribe to workspace change events
    space:subscribe("aerospace_workspace_change", function(env)
      local focused = env.FOCUSED_WORKSPACE
      local is_selected = (focused == sid)

      space:set({
        background = {
          border_width = is_selected and 2 or 0,
        },
        icon = {
          color = is_selected and colors.white or colors.accent,
        },
      })
    end)

    -- Update icons when windows change
    space:subscribe("space_windows_change", function(env)
      get_workspace_icons(sid, function(icons)
        space:set({ label = icons })
      end)
    end)

    -- Mouse click to switch workspace
    space:subscribe("mouse.clicked", function(env)
      sbar.exec("aerospace workspace " .. sid)
    end)
  end
end)

-- Load initial icons for all non-empty workspaces
sbar.exec("aerospace list-workspaces --all --empty no 2>/dev/null", function(result)
  if not result or result == "" then return end

  for sid in result:gmatch("[^\r\n]+") do
    get_workspace_icons(sid, function(icons)
      sbar.set("space." .. sid, { label = icons, drawing = true })
    end)
  end
end)

-- Get and highlight the currently focused workspace
sbar.exec("aerospace list-workspaces --focused 2>/dev/null", function(result)
  if not result or result == "" then return end
  local focused = result:gsub("%s+", "")
  sbar.trigger("aerospace_workspace_change", { FOCUSED_WORKSPACE = focused })
end)
