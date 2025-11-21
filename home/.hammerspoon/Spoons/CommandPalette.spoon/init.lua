local obj = {}
obj.__index = obj

obj.name = "CommandPalette"
obj.version = "0.1"
obj.author = "Meagan Waller"
obj.license = "MIT"

------------------------------------------------------------
-- Internal state
------------------------------------------------------------

-- All commands live in a flat array, but we keep group metadata for display.
obj._commands = {}
obj._commandIndex = {}
obj._chooser = nil
obj._hotkey = nil
obj._config = {
  maxRows = 12,
  width = 40, -- percent of screen
}

------------------------------------------------------------
-- Command structure:
-- {
--   id        = "string-id",
--   title     = "Human readable",
--   subtitle  = "Optional subtitle",
--   group     = "Dev" / "System" / etc.,
--   keywords  = { "git", "pull" },
--   fn        = function() ... end
-- }
------------------------------------------------------------

local function buildChoice(cmd)
  local groupPrefix = cmd.group and ("[" .. cmd.group .. "] ") or ""
  return {
    text   = groupPrefix .. cmd.title,
    subText = cmd.subtitle or "",
    uuid   = cmd.id,  -- safe identifier used to look up in _commandIndex
  }
end


local function rebuildChoices(self)
  if not self._chooser then return end

  local choices = {}
  for _, cmd in ipairs(self._commands) do
    table.insert(choices, buildChoice(cmd))
  end

  self._chooser:choices(choices)
end


------------------------------------------------------------
-- Public API
------------------------------------------------------------

-- Start palette with config:
--   palette:start({
--     maxRows = 15,
--     width   = 45,
--     commands = { ... } -- (optional)
--   })
function obj:start(config)
  self._commands = {}
  self._commandIndex = {}

  if config then
    if config.maxRows then self._config.maxRows = config.maxRows end
    if config.width then self._config.width = config.width end
  end

  self._chooser = hs.chooser.new(function(choice)
    if not choice then return end
    local id = choice.uuid
    if not id then return end
    local cmd = self._commandIndex[id]
    if cmd and cmd.fn then
      cmd.fn()
    end
  end)

  self._chooser
    :rows(self._config.maxRows)
    :width(self._config.width)
    :searchSubText(true)

  if config and config.commands then
    for _, cmd in ipairs(config.commands) do
      self:registerCommand(cmd)
    end
  else
    rebuildChoices(self)
  end

  return self
end

-- Register a single command
function obj:registerCommand(cmd)
  if not cmd or not cmd.id or not cmd.title or not cmd.fn then
    hs.printf("[CommandPalette] Invalid command: id, title, fn required")
    return self
  end

  -- store full command (with fn) only in Lua-side state
  table.insert(self._commands, cmd)
  self._commandIndex[cmd.id] = cmd

  rebuildChoices(self)
  return self
end


-- Register many commands at once
function obj:registerCommands(commands)
  if not commands then return self end
  for _, cmd in ipairs(commands) do
    self:registerCommand(cmd)
  end
  return self
end

-- Clear all commands
function obj:clearCommands()
  self._commands = {}
  self._commandIndex = {}
  rebuildChoices(self)
  return self
end

-- Show the palette
function obj:show()
  if not self._chooser then
    self:start()
  end
  self._chooser:show()
  return self
end

-- Hide palette
function obj:hide()
  if self._chooser then
    self._chooser:hide()
  end
  return self
end

-- Bind a normal hotkey (not Hyper) if you want
-- palette:bindHotkeys({ show = { modifiers = {"cmd","shift"}, key = "p" } })
function obj:bindHotkeys(mapping)
  if not mapping then return self end
  if self._hotkey then
    self._hotkey:delete()
    self._hotkey = nil
  end

  local spec = mapping.show or mapping["show"]
  if spec then
    self._hotkey = hs.hotkey.bind(spec.modifiers or {}, spec.key, function()
      self:show()
    end)
  end

  return self
end

-- Helper to build an app command (optional sugar)
function obj.appCommand(opts)
  -- opts: { id, title?, appName?, bundleID?, group?, subtitle? }
  if not opts.id then
    error("[CommandPalette] appCommand requires opts.id")
  end
  local title = opts.title or ("Open " .. (opts.appName or opts.bundleID or "App"))

  local function fn()
    if opts.bundleID then
      hs.application.launchOrFocusByBundleID(opts.bundleID)
    elseif opts.appName then
      hs.application.launchOrFocus(opts.appName)
    end
  end

  return {
    id       = opts.id,
    title    = title,
    subtitle = opts.subtitle or "",
    group    = opts.group or "Apps",
    fn       = fn,
  }
end

return obj
