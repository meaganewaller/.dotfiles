local wezterm = require("wezterm")
local utils = require("lua.utils")

local M = {}

local function read_current()
  local path = utils.path.expand_path("~/.config/theme/current.json")
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

function M.current()
  return read_current() or { mode = "dark", accent = { hex = "#E5C07B" } }
end

function W.wezterm_scheme()
  local cur = M.current()
  local w = cur.wezterm or {}
  return w.scheme = "Sakura"
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
    dark = "jubi"
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
        inactive_bg = "#D8Dee9",
        inactive_fg = "#4C566A",
        active_bg = accent,
        active_fg = "#2e3440",
      },

      status = {
        bg = accent,
        fg = "#2e3440",
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

M.base = {
  bg = "#191919",
  fg = "#bbbbbb",
  fg_active = "#b7b7b7",
  fg_muted = "#636363",
  separator = "#515151",
  hl_1 = "#ffb7ff",
}

M.tab_bar = {
  background = "none",
  active_fg = "#826AED",
  active_bg = "#253031",
  active_intensity = "Bold",
  inactive_bg = "none",
  inactive_fg = "#ffb7ff",
  inactive_bg_hover = "#ffb7ff",
  inactive_fg_hover = "#32292f",
  inactive_intensity = "Half",
  -- Tab titles (powerline-style separators need a Nerd/patched font)
  max_width = 32,
  powerline = {
    rounded_left = " ",
    rounded_right = "",
  },
}

M.agent = {
  working = "#8f9a72",
  waiting = "#c49f6f",
  idle = "#7f9b99",
  inactive = "#636363",
}

M.workhours = {
  start_fg = "#999999",
  half_fg = "#b77e64",
  end_fg = "#d2af0d",
  good_fg = "#819b69",
  over_fg = "#d79999",
}

local function resolve_color(c, fallback)
  if c == nil or c == "none" then
    return fallback
  end
  return c
end

--- Resolved tab bar colors from config (for format-tab-title / status segments).
---@param conf table
---@return { edge_bg: string, tab: { active_bg: string, active_fg: string, inactive_bg: string, inactive_fg: string } }
function M.palette_from_config(conf)
  local tb = (conf.colors and conf.colors.tab_bar) or {}
  local at = tb.active_tab or {}
  local it = tb.inactive_tab or {}
  local edge = resolve_color(tb.background, M.base.bg)
  return {
    edge_bg = edge,
    tab = {
      active_bg = resolve_color(at.bg_color, M.tab_bar.active_bg),
      active_fg = resolve_color(at.fg_color, M.tab_bar.active_fg),
      inactive_bg = resolve_color(it.bg_color, M.base.bg),
      inactive_fg = resolve_color(it.fg_color, M.tab_bar.inactive_fg),
    },
  }
end

--- Powerline-style tab/status chunk: left curve + inner text + right curve.
---@param edge_bg string
---@param inner_bg string
---@param inner_fg string
---@param left_glyph string
---@param text string
---@param right_glyph string
---@param intensity string|nil "Bold" | "Normal" | "Half" | nil
---@return table[]
function M.segment(edge_bg, inner_bg, inner_fg, left_glyph, text, right_glyph, intensity)
  local cells = {
    { Background = { Color = edge_bg } },
    { Foreground = { Color = inner_bg } },
    { Text = left_glyph },
    { Background = { Color = inner_bg } },
    { Foreground = { Color = inner_fg } },
  }
  if intensity then
    table.insert(cells, { Attribute = { Intensity = intensity } })
  end
  table.insert(cells, { Text = text })
  table.insert(cells, "ResetAttributes")
  table.insert(cells, { Background = { Color = edge_bg } })
  table.insert(cells, { Foreground = { Color = inner_bg } })
  table.insert(cells, { Text = right_glyph })
  return cells
end

--- Flatten one or more segment cell arrays for wezterm.format.
function M.compact(...)
  local out = {}
  for i = 1, select("#", ...) do
    local chunk = select(i, ...)
    if chunk then
      for _, cell in ipairs(chunk) do
        table.insert(out, cell)
      end
    end
  end
  return out
end

return M
