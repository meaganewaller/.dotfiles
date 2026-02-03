local wezterm = require("wezterm")

local M = {}

local function read_current()
  local path = wezterm.home_dir .. "/.config/theme/current.json"
  local ok, data = pcall(function()
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return wezterm.json_parse(s)
  end)
  if ok then return data end
  return nil
end

-- Return full current theme data
function M.current()
  return read_current() or { mode = "dark", accent = { hex = "#E5C07B" } }
end

function M.wezterm_scheme()
  local cur = M.current()
  local w = cur.wezterm or {}
  return w.scheme or "Sakura"
end

function M.appearance()
  local ok, gui = pcall(function()
    return wezterm.gui
  end)
  if not ok or not gui then
    return "Dark"
  end
  return wezterm.gui.get_appearance()
end

function M.is_dark()
  local cur = M.current()
  return cur.mode == "dark"
end

function M.pick(tbl)
  return M.is_dark() and tbl.dark or tbl.light
end

function M.scheme()
  return M.pick({
    light = "Sakura",
    dark = "jubi",
  })
end

function M.palette()
  local cur = M.current()
  local mode = cur.mode or "dark"
  local accent = (cur.accent or {}).hex or "#E5C07B"

  if mode == "light" then
    return {
      term_background = "#FAFAF9",
      edge_bg = "rgba(0 0 0 0)",

      tab = {
        inactive_bg = "#D8DEE9",
        inactive_fg = "#4C566A",
        active_bg = accent,
        active_fg = "#2E3440",
      },

      status = {
        bg = accent,
        fg = "#2E3440",
      },
    }
  else
    return {
      term_background = "#1A1D24",
      edge_bg = "rgba(0 0 0 0)",

      tab = {
        inactive_bg = "#65737E",
        inactive_fg = "#F0F2F5",
        active_bg = accent,
        active_fg = "#282C34",
      },

      status = {
        bg = accent,
        fg = "#f0f2f5",
      },
    }
  end
end

-- Powerline-ish segment builder
function M.segment(edge_bg, bg, fg, left_glyph, text, right_glyph, intensity)
  return {
    { Background = { Color = edge_bg } },
    { Foreground = { Color = bg } },
    { Text = left_glyph },

    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    intensity and { Attribute = { Intensity = intensity } } or nil,
    { Text = text },

    { Background = { Color = edge_bg } },
    { Foreground = { Color = bg } },
    { Text = right_glyph },
  }
end

-- Remove nil entries (because we conditionally insert intensity)
function M.compact(fmt)
  local out = {}
  for _, v in ipairs(fmt) do
    if v ~= nil then
      table.insert(out, v)
    end
  end
  return out
end

return M
