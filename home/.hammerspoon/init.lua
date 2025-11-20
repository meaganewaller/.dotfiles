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
