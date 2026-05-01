-- ============================================================================
-- @module       theme
-- @description  Public API for loading color palettes. Used by both the Ghostty
--               sync script (scripts/sync-theme.lua) and the Neovim bridge
--               (nvim/lua/theme-bridge/init.lua).
--
--               This module is PURE LUA — no vim.* dependencies. It works in:
--                 • nvim -l (headless Neovim)
--                 • luajit (standalone)
--                 • lua 5.1+ (PUC Lua)
--                 • require() inside a running Neovim instance
--
-- @since        1.0.0
-- @usage        local theme = assert(loadfile("/path/to/theme/init.lua"))()
--               local palette = theme.get_active()
-- @see          theme/schema.lua  — type definitions
-- @see          theme/active.lua  — active palette selector
-- ============================================================================

local M = {}

-- ── Root Directory Detection ────────────────────────────────────────────────

--- @description  Auto-detect the directory containing this init.lua file
---               using debug.getinfo. Falls back to XDG_CONFIG_HOME.
--- @return       string  Absolute or relative path to the theme/ directory
--- @type         string
local function detect_root()
  local raw_source = debug.getinfo(1, "S").source or ""
  local dir = raw_source:match("@(.+)/")
  if dir then
    return dir
  end
  -- Fallback: XDG standard path
  local home = os.getenv("HOME") or ""
  local xdg = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
  return xdg .. "/ghostty/theme"
end

--- @type string
M._root = detect_root()

-- ── Public API ──────────────────────────────────────────────────────────────

--- @description  Get the slug of the currently active palette.
--- @return       string  Palette slug (e.g. "catppuccin-mocha")
function M.get_active_name()
  local path = M._root .. "/active.lua"
  local chunk, err = loadfile(path)
  if not chunk then
    error("[theme] Cannot load active.lua: " .. path .. "\n" .. tostring(err))
  end
  return chunk()
end

--- @description  Load a palette by slug name. If no name is given, loads
---               the active palette (from active.lua).
--- @param        name? string  Palette slug (optional, defaults to active)
--- @return       Palette       The palette table
function M.get_palette(name)
  name = name or M.get_active_name()
  local path = M._root .. "/palettes/" .. name .. ".lua"
  local chunk, err = loadfile(path)
  if not chunk then
    error(
      "[theme] Cannot load palette '"
        .. name
        .. "' from: "
        .. path
        .. "\n"
        .. tostring(err)
        .. "\n\nAvailable palettes:\n  "
        .. table.concat(M.list_palettes(), "\n  ")
    )
  end
  return chunk()
end

--- @description  Shorthand: load the currently active palette.
--- @return       Palette
function M.get_active()
  return M.get_palette()
end

--- @description  List all available palette slugs by scanning the palettes/
---               directory. Requires io.popen (available on all Unix systems).
--- @return       string[]  Array of palette slug strings
function M.list_palettes()
  local palettes = {}
  local dir = M._root .. "/palettes/"
  local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
  if handle then
    for line in handle:lines() do
      local slug = line:match("^(.+)%.lua$")
      if slug then
        table.insert(palettes, slug)
      end
    end
    handle:close()
  end
  table.sort(palettes)
  return palettes
end

--- @description  Validate that a palette table conforms to the expected schema.
---               Returns true if valid, false + error message otherwise.
--- @param        palette Palette  The palette table to validate
--- @return       boolean valid
--- @return       string? error_message
function M.validate(palette)
  local required_root = {
    "meta",
    "foreground",
    "background",
    "cursor",
    "selection_fg",
    "selection_bg",
    "ansi",
    "semantic",
  }
  for _, key in ipairs(required_root) do
    if palette[key] == nil then
      return false, "Missing required field: " .. key
    end
  end

  local required_meta = { "name", "slug", "style", "variant" }
  for _, key in ipairs(required_meta) do
    if palette.meta[key] == nil then
      return false, "Missing required field: meta." .. key
    end
  end

  local ansi_names = { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" }
  for _, name in ipairs(ansi_names) do
    if not palette.ansi[name] then
      return false, "Missing ANSI color: ansi." .. name
    end
    if not palette.ansi[name].normal or not palette.ansi[name].bright then
      return false, "Missing normal/bright for: ansi." .. name
    end
  end

  return true, nil
end

return M
