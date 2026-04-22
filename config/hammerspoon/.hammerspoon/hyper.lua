------------------------------------------------------------
-- hyper.lua
--
-- A small "Hyper" router:
--  - Uses a single key (F18/F19) as a modal leader
--  - Lets you bind Hyper+key (and Hyper+modifier+key)
--  - Supports per-app "local bindings" that send ⌘⌥⇧⌃+key
--    for apps that only understand the traditional hyper chord.
--
-- Config shape:
--   {
--     hyperKey = "F18", -- or "F19"
--     applications = {
--       ['Things'] = {
--         bundleID      = 'com.culturedcode.ThingsMac',
--         hyper_key     = 't',          -- Hyper+t launches/focuses
--         local_bindings = { ',', '.' } -- Hyper+comma, Hyper+dot send ⌘⌥⇧⌃+key
--       },
--       ['Obsidian'] = {
--         name     = 'Obsidian',
--         hyper_key = 'o',
--       },
--     }
--   }
------------------------------------------------------------

local Hyper = {}
Hyper.__index = Hyper

local HYPER_CHORD = { "cmd", "alt", "shift", "ctrl" }

------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------

local function findApp(appCfg)
  if appCfg.bundleID then
    return hs.application.find(appCfg.bundleID)
  end
  if appCfg.name then
    return hs.application.find(appCfg.name)
  end
  return nil
end

local function launchApp(appCfg)
  if appCfg.bundleID then
    hs.application.launchOrFocusByBundleID(appCfg.bundleID)
  elseif appCfg.name then
    hs.application.launchOrFocus(appCfg.name)
  end
end

local function waitForApp(appCfg, cb, timeout)
  timeout = timeout or 5
  local start = os.time()

  local function check()
    local app = findApp(appCfg)
    if app then
      cb(app)
      return
    end
    if os.difftime(os.time(), start) >= timeout then
      hs.alert.show("Hyper: app timed out: " .. (appCfg.name or appCfg.bundleID or "?"))
      return
    end
    hs.timer.doAfter(0.2, check)
  end

  check()
end

local function sendHyperChordKey(key)
  hs.eventtap.keyStroke(HYPER_CHORD, key, 0)
end

------------------------------------------------------------
-- Constructor / start
------------------------------------------------------------

function Hyper.start(config)
  local self = setmetatable({}, Hyper)

  self.config       = config or {}
  self.hyperKey     = self.config.hyperKey or "F18"
  self.applications = self.config.applications or {}

  -- single modal for everything
  self.modal = hs.hotkey.modal.new({}, self.hyperKey)

  function self.modal:entered()
    -- uncomment if you want feedback
    -- hs.alert.show("Hyper", 0.2)
  end

  function self.modal:exited()
    -- nothing
  end

  -- Bind app launchers & local bindings from config
  self:_bindApplications()
  self:_bindLocalBindings()

  return self
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

-- Bind Hyper+mods+key to a function.
-- Example:
--   hyper:bind({}, 'r', function() hs.console.hswindow():focus() end)
--   hyper:bind({'shift'}, 'r', function() hs.reload() end)
function Hyper:bind(mods, key, fn)
  mods = mods or {}

  self.modal:bind(mods, key,
    function() -- keyDown: do nothing
    end,
    function() -- keyUp: run the action, exit modal
      self.modal:exit()
      if fn then fn() end
    end
  )

  return self
end

------------------------------------------------------------
-- Config-driven app bindings
------------------------------------------------------------

function Hyper:_bindApplications()
  for label, appCfg in pairs(self.applications) do
    local key = appCfg.hyper_key
    if key then
      self:bind({}, key, function()
        local app = findApp(appCfg)
        if app then
          app:activate()
        else
          launchApp(appCfg)
        end
      end)
    end
  end
end

-- "Local bindings" = translate Hyper+key → ⌘⌥⇧⌃+key
-- so you can use that in Things / Drafts / Alfred etc.
function Hyper:_bindLocalBindings()
  for label, appCfg in pairs(self.applications) do
    if appCfg.local_bindings and type(appCfg.local_bindings) == "table" then
      for _, key in ipairs(appCfg.local_bindings) do
        self:bind({}, key, function()
          -- If app is running: just send the hyper chord
          if findApp(appCfg) then
            sendHyperChordKey(key)
          else
            -- Launch, then send the chord when it's ready
            launchApp(appCfg)
            waitForApp(appCfg, function()
              sendHyperChordKey(key)
            end)
          end
        end)
      end
    end
  end
end

return Hyper

