-- events.lua
local wezterm = require("wezterm")
local util = require("util")
local theme = require("theme")

local M = {}

local function tab_title(tab_info)
  local t = tab_info.tab_title
  if t and #t > 0 then
    return t
  end
  return util.basename(tab_info.active_pane.title)
end

function M.register(config)
  wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
    local p = theme.palette()
    local edge_bg = config.colors.tab_bar.background

    local active = tab.is_active or hover
    local bg = active and p.tab.active_bg or p.tab.inactive_bg
    local fg = active and p.tab.active_fg or p.tab.inactive_fg

    local title = tab_title(tab)

    -- room for edges + index
    local max = config.tab_max_width - 9
    if #title > max then
      title = wezterm.truncate_right(title, max) .. "…"
    end

    local intensity = tab.is_active and "Bold" or "Normal"
    local text = " " .. (tab.tab_index + 1) .. ": " .. title .. " "

    return theme.compact(theme.segment(edge_bg, bg, fg, " ", text, "", intensity))
  end)

  wezterm.on("format-window-title", function(tab, pane, tabs, panes, cfg)
    return string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
  end)

  wezterm.on("update-right-status", function(window, pane)
    local p = theme.palette()
    local edge_bg = config.colors.tab_bar.background

    local text = " 󰡚 " .. window:active_workspace() .. " "
    local seg = theme.compact(theme.segment(edge_bg, p.status.bg, p.status.fg, " ", text, "", nil))

    window:set_right_status(wezterm.format({
      table.unpack(seg),
      { Text = " " },
    }))
  end)

  wezterm.on("gui-startup", function()
    local _, _, window = wezterm.mux.spawn_window({})
    window:gui_window():maximize()
  end)
end

return M
