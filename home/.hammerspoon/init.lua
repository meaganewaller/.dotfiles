---------------------------------------
-- Hammerspoon init.lua
---------------------------------------

-- Quick reload when files change in ~/.hammerspoon
local function reloadConfig(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon", reloadConfig):start()
hs.alert.show("Hammerspoon config loaded")

local function focusedWindow()
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window")
    return nil
  end
  return win
end

local function moveWindow(unit)
  local win = focusedWindow()
  if not win then return end
  win:move(unit, nil, true, 0)
end

local function centerMouseInFocusedWindow()
  local win = focusedWindow()
  if not win then return end
  local f = win:frame()
  local p = hs.geometry.point(f.x + f.w / 2, f.y + f.h / 2)
  hs.mouse.setAbsolutePosition(p)
end

local config = {}

config.hyperKey = "F18"  -- or "F19" if you prefer

config.applications = {
  ['Things'] = {
    bundleID      = 'com.culturedcode.ThingsMac',
    hyper_key     = 't',          -- Hyper+t → focus/launch Things
    local_bindings = { ',', '.' } -- Hyper+comma/dot → ⌘⌥⇧⌃+key (Quick Entry, etc.)
  },

  ['Obsidian'] = {
    name      = 'Obsidian',
    hyper_key = 'o',
  },

  ['Arc'] = {
    name      = 'Arc',
    hyper_key = 'a',
  },

  ['Slack'] = {
    name      = 'Slack',
    hyper_key = 's',
  },

  ['VSCode'] = {
    name      = 'Visual Studio Code',
    hyper_key = 'v',
  },

  ['iTerm'] = {
    name      = 'iTerm',
    hyper_key = 'i',
  },
}

hyper = require('hyper').start(config)

-- HYPER+⇧+r → reload config
hyper:bind({ 'shift' }, 'r', function()
  hs.reload()
end)

hyper:bind({}, 'h', function()
  moveWindow({ x = 0,   y = 0,   w = 0.5, h = 1 })
end)

hyper:bind({}, 'l', function()
  moveWindow({ x = 0.5, y = 0,   w = 0.5, h = 1 })
end)

hyper:bind({}, 'k', function()
  moveWindow({ x = 0,   y = 0,   w = 1,   h = 0.5 })
end)

hyper:bind({}, 'j', function()
  moveWindow({ x = 0,   y = 0.5, w = 1,   h = 0.5 })
end)

-- HYPER+m → “nice centered” window
hyper:bind({}, 'm', function()
  moveWindow({ x = 0.15, y = 0.08, w = 0.7, h = 0.84 })
end)

-- HYPER+f → true fullscreen
hyper:bind({}, 'f', function()
  local win = focusedWindow()
  if not win then return end
  win:maximize(0)
end)

-- HYPER+c → center mouse in focused window
hyper:bind({}, 'c', centerMouseInFocusedWindow)


local desktopPath = os.getenv("HOME") .. "/Desktop"

local function renameScreenshot(files)
  for _, file in ipairs(files) do
    local name = file:match("([^/]+)$")
    if name and name:match("^Screenshot") and name:match("%.png$") then
      local app = hs.application.frontmostApplication()
      local appName = app and app:name() or "screen"
      appName = appName:gsub("%s+", "-"):lower()

      local ts = os.date("%Y%m%d-%H%M%S")
      local newName = string.format("shot-%s-%s.png", appName, ts)
      local newPath = desktopPath .. "/" .. newName

      os.rename(file, newPath)
      hs.alert.show("Renamed: " .. newName, 0.8)
    end
  end
end

hs.pathwatcher.new(desktopPath, renameScreenshot):start()
