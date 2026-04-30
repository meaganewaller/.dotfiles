local is_windows = package.config:sub(0, 1) == "\\"
local wezterm = require("wezterm")
local agent_deck = require("lua.agent")
local theme = require("lua.theme")

local DIV_R = theme.tab_bar.powerline and theme.tab_bar.powerline.rounded_right or utf8.char(0xe0b4)
local TAB_MAX = theme.tab_bar.max_width or 32
-- Rounded dividers: no extra pad after tab text (matches bar plugin behavior)
local TAB_TEXT_PAD = ""

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
  if tab.tab_title and tab.tab_title ~= "" then
    return tab.tab_title
  end
  return tab.active_pane.title
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

local function format_tab_title(tab, tabs, _, conf, _hover, _max_width)
  local colours = conf.resolved_palette.tab_bar

  local active_tab_index = 0
  for _, t in ipairs(tabs) do
    if t.is_active then
      active_tab_index = t.tab_index
    end
  end

  local rainbow = {
    conf.resolved_palette.ansi[2],
    conf.resolved_palette.indexed[16],
    conf.resolved_palette.ansi[4],
    conf.resolved_palette.ansi[3],
    conf.resolved_palette.ansi[5],
    conf.resolved_palette.ansi[6],
  }

  local i = tab.tab_index % 6
  local active_bg = rainbow[i + 1]
  local active_fg = colours.background
  local inactive_bg = colours.inactive_tab.bg_color
  local inactive_fg = colours.inactive_tab.fg_color
  local new_tab_bg = colours.new_tab.bg_color

  local s_bg, s_fg, e_bg, e_fg

  if tab.tab_index == #tabs - 1 then
    if tab.is_active then
      s_bg = active_bg
      s_fg = active_fg
      e_bg = new_tab_bg
      e_fg = active_bg
    else
      s_bg = inactive_bg
      s_fg = inactive_fg
      e_bg = new_tab_bg
      e_fg = inactive_bg
    end
  elseif tab.tab_index == active_tab_index - 1 then
    s_bg = inactive_bg
    s_fg = inactive_fg
    e_bg = rainbow[(i + 1) % 6 + 1]
    e_fg = inactive_bg
  elseif tab.is_active then
    s_bg = active_bg
    s_fg = active_fg
    e_bg = inactive_bg
    e_fg = active_bg
  else
    s_bg = inactive_bg
    s_fg = inactive_fg
    e_bg = inactive_bg
    e_fg = inactive_bg
  end

  local pane_count = ""
  local mux_tab = wezterm.mux.get_tab(tab.tab_id)
  if mux_tab then
    local n = #mux_tab:panes()
    if n > 1 then
      pane_count = to_superscript(n)
    end
  end

  local index = string.format("%d: ", tab.tab_index + 1)

  local fillerwidth = 2 + #index + #pane_count + 2
  local tabtitle = tab_title_text(tab)
  local width = conf.tab_max_width - fillerwidth - 1
  if (#tabtitle + fillerwidth) > conf.tab_max_width then
    tabtitle = wezterm.truncate_right(tabtitle, width) .. "…"
  end

  local icon_segments = collect_agent_icons(tab, s_fg)

  local cells = {
    { Background = { Color = s_bg } },
    { Foreground = { Color = s_fg } },
    { Text = string.format(" %s", index) },
  }

  for _, seg in ipairs(icon_segments) do
    table.insert(cells, { Foreground = { Color = seg.fg } })
    table.insert(cells, { Text = seg.text })
  end

  if #icon_segments > 0 then
    table.insert(cells, { Foreground = { Color = s_fg } })
    table.insert(cells, { Text = " " })
  end

  table.insert(cells, { Text = tabtitle .. pane_count .. TAB_TEXT_PAD })
  table.insert(cells, { Background = { Color = e_bg } })
  table.insert(cells, { Foreground = { Color = e_fg } })
  table.insert(cells, { Text = DIV_R })

  return cells
end

return function(config)
  config.tab_bar_at_bottom = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.show_new_tab_button_in_tab_bar = false
  config.tab_max_width = TAB_MAX

  wezterm.on("format-tab-title", format_tab_title)
end
