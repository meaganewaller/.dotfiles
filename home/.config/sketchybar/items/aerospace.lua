-- Aerospace workspace integration for sketchybar
-- Multi-monitor setup:
--   Display 1: DELL U2417H (vertical, left) - Communication
--   Display 2: S34J55x (main, center)       - Primary work
--   Display 3: Built-in Retina (right)      - Entertainment
-- Single monitor: All workspaces on display 1

local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Register the aerospace workspace change event
sbar.add("event", "aerospace_workspace_change")

-- Workspace to display mapping (multi-monitor)
-- Sketchybar display order (macOS main display = 1):
--   1 = S34J55x (main, center)
--   2 = Built-in Retina (right)
--   3 = DELL U2417H (left, vertical)
local workspace_display_multi = {
  -- Main monitor (center) - Primary work
  ["1"] = 1, ["2"] = 1, ["3"] = 1, ["4"] = 1,
  ["5"] = 1, ["6"] = 1, ["7"] = 1,

  -- Dell vertical (left) - Communication
  ["S"] = 3, ["M"] = 3, ["D"] = 3, ["C"] = 3,

  -- Built-in (right) - Entertainment
  ["E"] = 2, ["Y"] = 2, ["P"] = 2, ["8"] = 2, ["9"] = 2,
}

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

-- Define workspace order
local workspace_order = {
  -- Main monitor
  "1", "2", "3", "4", "5", "6", "7",
  -- Dell vertical
  "S", "M", "D", "C",
  -- Built-in
  "E", "Y", "P", "8", "9",
}

-- Track created workspaces
local spaces = {}

-- Initialize workspaces after detecting monitor count
sbar.exec("aerospace list-monitors 2>/dev/null | wc -l", function(result)
  local monitor_count = tonumber(result:match("%d+")) or 1

  -- Get display for workspace, adapting to single/multi monitor
  local function get_display_for_workspace(sid)
    if monitor_count <= 1 then
      return 1  -- Single monitor: everything on display 1
    end
    return workspace_display_multi[sid] or 2
  end

  -- Create workspace items
  for _, sid in ipairs(workspace_order) do
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

    spaces[sid] = space

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

    -- Mouse click to switch workspace
    space:subscribe("mouse.clicked", function(env)
      sbar.exec("aerospace workspace " .. sid)
    end)
  end

  -- Load initial icons for all non-empty workspaces
  sbar.exec("aerospace list-workspaces --all --empty no 2>/dev/null", function(ws_result)
    if not ws_result or ws_result == "" then return end

    for sid in ws_result:gmatch("[^\r\n]+") do
      if spaces[sid] then
        get_workspace_icons(sid, function(icons)
          spaces[sid]:set({ label = icons })
        end)
      end
    end
  end)

  -- Get and highlight the currently focused workspace
  sbar.exec("aerospace list-workspaces --focused 2>/dev/null", function(focused_result)
    if not focused_result or focused_result == "" then return end
    local focused = focused_result:gsub("%s+", "")
    sbar.trigger("aerospace_workspace_change", { FOCUSED_WORKSPACE = focused })
  end)
end)

-- Update icons when windows change on any workspace
local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

space_window_observer:subscribe("space_windows_change", function(env)
  -- Refresh icons for the affected workspace
  if env.INFO and env.INFO.space then
    local sid = tostring(env.INFO.space)
    if spaces[sid] then
      get_workspace_icons(sid, function(icons)
        spaces[sid]:set({ label = icons })
      end)
    end
  end
end)

-- Periodic refresh of all workspace icons (every 5 seconds)
local icon_refresher = sbar.add("item", {
  drawing = false,
  update_freq = 5,
})

icon_refresher:subscribe("routine", function()
  for sid, space in pairs(spaces) do
    get_workspace_icons(sid, function(icons)
      space:set({ label = icons })
    end)
  end
end)
