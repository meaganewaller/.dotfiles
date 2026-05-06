---------------------------------------
-- Hammerspoon init.lua
-- Meagan's Hyper + Command Palette setup
---------------------------------------

---------------------------------------
-- Bootstrap
---------------------------------------

hs.alert.show("Hammerspoon config loaded")

---------------------------------------
-- Window helpers
---------------------------------------

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

---------------------------------------
-- Hyper config + bindings
---------------------------------------

local config = {}

-- Karabiner should map some key (e.g. right_command alone) → F18
config.hyperKey = "F18"

config.applications = {
  Chrome = {
    bundleID = "com.google.Chrome",
    hyper_key = "b",
  },
  Obsidian = {
    name = "Obsidian",
    hyper_key = "o",
  },
  Slack = {
    name = "Slack",
    hyper_key = "s",
  },
  Cursor = {
    name = "Cursor",
    hyper_key = "c",
  },
  VSCode = {
    name = "Visual Studio Code",
    hyper_key = "v",
  },
  WezTerm = {
    name = "WezTerm",
    hyper_key = "t",
  },
}

hyper = require("hyper").start(config)

-- HYPER+⇧+r → reload config
hyper:bind({ "shift" }, "r", function()
  hs.reload()
end)

-- HYPER+h/j/k/l → window tiling (vim-style)
hyper:bind({}, "h", function()
  moveWindow({ x = 0,   y = 0,   w = 0.5, h = 1 })
end)

hyper:bind({}, "l", function()
  moveWindow({ x = 0.5, y = 0,   w = 0.5, h = 1 })
end)

hyper:bind({}, "k", function()
  moveWindow({ x = 0,   y = 0,   w = 1,   h = 0.5 })
end)

hyper:bind({}, "j", function()
  moveWindow({ x = 0,   y = 0.5, w = 1,   h = 0.5 })
end)

-- HYPER+m → “nice centered” window
hyper:bind({}, "m", function()
  moveWindow({ x = 0.15, y = 0.08, w = 0.7, h = 0.84 })
end)

-- HYPER+f → true fullscreen
hyper:bind({}, "f", function()
  local win = focusedWindow()
  if not win then return end
  win:maximize(0)
end)

-- HYPER+c → center mouse in focused window
hyper:bind({}, "c", centerMouseInFocusedWindow)

---------------------------------------
-- Screenshot renamer (Desktop)
---------------------------------------

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
---------------------------------------
-- Command Palette Spoon
---------------------------------------

hs.loadSpoon("CommandPalette")

local function appCommand(opts)
  return {
    id = opts.id,
    title = opts.title or ("Open " .. opts.appName),
    subtitle = opts.subtitle or "",
    group = opts.group or "Apps",
    fn = function()
      if opts.bundleID then
        hs.application.launchOrFocusByBundleID(opts.bundleID)
      elseif opts.appName then
        hs.application.launchOrFocus(opts.appName)
      end
    end,
  }
end

-- start the palette with basic config (no commands yet)
local palette = spoon.CommandPalette:start({
  maxRows = 14,
  width   = 45,
})

-- now register commands explicitly
palette:registerCommands({
  -- Modes
  {
    id       = "coding-mode",
    title    = "Enter Coding Mode",
    subtitle = "WezTerm + Cursor + Slack",
    group    = "Modes",
    fn       = function()
      hs.alert.show("Coding Mode", 1)
      hs.application.launchOrFocus("Cursor")
      hs.application.launchOrFocus("WezTerm") -- note capital T
      hs.application.launchOrFocus("Slack")
    end,
  },

  -- System
  {
    id    = "reload-hs",
    title = "Reload Hammerspoon config",
    group = "System",
    fn    = function()
      hs.reload()
    end,
  },

  {
    id    = "toggle-dark-mode",
    title = "Toggle Dark Mode",
    group = "System",
    fn    = function()
      hs.osascript.applescript([[
        tell application "System Events"
          tell appearance preferences
            set dark mode to not dark mode
          end tell
        end tell
      ]])
    end,
  },
})

-- Hyper + Space → Command Palette
hyper:bind({}, "space", function()
  palette:show()
end)

-- Also Cmd+Shift+P (VSCode muscle memory)
palette:bindHotkeys({
  show = { modifiers = { "cmd", "shift" }, key = "p" },
})
