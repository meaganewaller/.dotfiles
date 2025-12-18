local wezterm = require("wezterm")

local M = {}

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
  return M.appearance():find("Dark") ~= nil
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
  return {
    term_background = "#E0E2EA",
    edge_bg = "rgba(0 0 0 0)",

    tab = {
      inactive_bg = "#65737E",
      inactive_fg = "#F0F2F5",
      active_bg = "#E5C07B",
      active_fg = "#282C34",
    },

    status = {
      bg = "#b4713d",
      fg = "#f0f2f5",
    },
  }
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
