local path_utils = require("lua.utils.path")
local wezterm = require("wezterm")
local agent_deck = require("lua.agent")
local theme = require("lua.theme")

local TAB_MAX = theme.tab_bar.max_width or 32
local PL = theme.tab_bar.powerline or {}
local ROUND_L = PL.rounded_left or " "
local ROUND_R = PL.rounded_right or ""

local superscript_digits = {
  "⁰",
  "¹",
  "²",
  "³",
  "⁴",
  "⁵",
  "⁶",
  "⁷",
  "⁸",
  "⁹",
}

local function to_superscript(n)
  local s = tostring(n)
  local out = {}
  for i = 1, #s do
    local ch = s:sub(i, i)
    local d = tonumber(ch)
    if d then
      table.insert(out, superscript_digits[d + 1])
    else
      table.insert(out, ch)
    end
  end
  return table.concat(out)
end

local function tab_title_text(tab)
  local t = tab.tab_title
  if t and #t > 0 then
    return t
  end
  return path_utils.basename(tab.active_pane.title)
end

local function collect_agent_icons(tab)
  local segments = {}
  if not agent_deck then
    return segments
  end
  for _, pane_info in ipairs(tab.panes or {}) do
    local pane_state
    local ok, mux_pane = pcall(wezterm.mux.get_pane, pane_info.pane_id)
    if ok and mux_pane then
      pane_state = agent_deck.update_pane(mux_pane)
    end
    if pane_state == nil then
      pane_state = agent_deck.get_agent_state(pane_info.pane_id)
    end
    if agent_deck.should_render_state(pane_state) then
      table.insert(segments, {
        fg = agent_deck.get_status_color(pane_state.status),
        text = agent_deck.get_status_icon(pane_state.status),
      })
    end
  end
  return segments
end

local function format_tab_title(tab, _tabs, _, conf, hover, _)
  local p = theme.palette_from_config(conf)
  local edge_bg = p.edge_bg

  local active = tab.is_active or hover
  local bg = active and p.tab.active_bg or p.tab.inactive_bg
  local fg = active and p.tab.active_fg or p.tab.inactive_fg
  local intensity
  if tab.is_active then
    intensity = theme.tab_bar.active_intensity or "Bold"
  elseif hover then
    intensity = "Normal"
  else
    intensity = theme.tab_bar.inactive_intensity or "Half"
  end

  local icon_segments = collect_agent_icons(tab)

  local pane_count = ""
  local mux_tab = wezterm.mux.get_tab(tab.tab_id)
  if mux_tab then
    local n = #mux_tab:panes()
    if n > 1 then
      pane_count = to_superscript(n)
    end
  end

  local title = tab_title_text(tab)
  local index_prefix = " " .. (tab.tab_index + 1) .. ": "
  local approx_icons = 0
  for _, seg in ipairs(icon_segments) do
    approx_icons = approx_icons + #seg.text
  end
  local reserve = #index_prefix + approx_icons + #pane_count + 8
  local max_title = math.max(6, conf.tab_max_width - reserve)
  if #title > max_title then
    title = wezterm.truncate_right(title, max_title) .. "…"
  end

  local cells = {
    { Background = { Color = edge_bg } },
    { Foreground = { Color = bg } },
    { Text = ROUND_L },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = intensity } },
    { Text = index_prefix },
  }

  for _, seg in ipairs(icon_segments) do
    table.insert(cells, { Foreground = { Color = seg.fg } })
    table.insert(cells, { Text = seg.text })
  end

  if #icon_segments > 0 then
    table.insert(cells, { Foreground = { Color = fg } })
    table.insert(cells, { Text = " " })
  end

  table.insert(cells, { Text = title .. pane_count .. " " })
  table.insert(cells, "ResetAttributes")
  table.insert(cells, { Background = { Color = edge_bg } })
  table.insert(cells, { Foreground = { Color = bg } })
  table.insert(cells, { Text = ROUND_R })

  return cells
end

return function(config)
  config.tab_bar_at_bottom = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.show_new_tab_button_in_tab_bar = false
  config.tab_max_width = TAB_MAX

  if not path_utils.is_windows then
    local status_bar_offset_cols = 44
    local window_cols = wezterm.GLOBAL.window_cols or {}
    wezterm.GLOBAL.window_cols = window_cols

    local function window_key(window)
      local ok, id = pcall(function()
        return window:window_id()
      end)
      return (ok and id ~= nil) and tostring(id) or "default"
    end

    local function refresh_cols(window)
      local tab = window:active_tab()
      if tab then
        window_cols[window_key(window)] = tab:get_size().cols - status_bar_offset_cols
      end
    end

    wezterm.on("window-config-reloaded", refresh_cols)
    wezterm.on("window-resized", refresh_cols)
  end

  wezterm.on("format-tab-title", format_tab_title)

  wezterm.on("format-window-title", function(tab, _, tabs, _, _)
    return string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
  end)
end
