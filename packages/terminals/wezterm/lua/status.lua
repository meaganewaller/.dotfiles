local is_windows = package.config:sub(0, 1) == "\\"
local wezterm = require("wezterm")
local agent_deck = require("lua.agent")
local theme = require("lua.theme")
local time_utils = require("lua.utils.time")

local DIV_R = (theme.tab_bar.powerline and theme.tab_bar.powerline.rounded_right) or utf8.char(0xe0b4)

local KEY_TABLE_LABELS = {
  resize_mode = "RESIZE",
  copy_mode = "VISUAL",
  search_mode = "SEARCH",
}

-- Pre-allocate color tables to reduce allocations
local color_gray = { Color = theme.base.fg_muted }
local color_separator = { Color = theme.base.separator }
local color_white = { Color = theme.base.fg }
local color_waiting = { Color = theme.agent.waiting }
local color_workhours_start = { Color = theme.workhours.start_fg }
local color_workhours_half = { Color = theme.workhours.half_fg }
local color_workhours_end = { Color = theme.workhours.end_fg }
local color_workhours_good = { Color = theme.workhours.good_fg }
local color_workhours_over = { Color = theme.workhours.over_fg }

-- Reusable status table structure
local status = {}

local function get_workhours_display(window)
  local wday = os.date("*t").wday
  if wday == 1 or wday == 7 then
    return nil
  end

  local mux_window = window:mux_window()
  if mux_window == nil then
    return wezterm.nerdfonts.fa_hourglass_start, "-.-", color_workhours_start
  end

  local active_pane = mux_window:active_pane()
  if active_pane == nil then
    return wezterm.nerdfonts.fa_hourglass_start, "-.-", color_workhours_start
  end

  local user_vars = active_pane:get_user_vars() or {}
  local hours_worked = time_utils.calculate_hour_difference(user_vars.first_login, wezterm.strftime("%I:%M:%S"))
  if hours_worked == nil or hours_worked <= 0 or hours_worked >= 10 then
    return wezterm.nerdfonts.fa_hourglass_start, "-.-", color_workhours_start
  end

  local icon = wezterm.nerdfonts.fa_hourglass_start
  local color = color_workhours_start
  if hours_worked > 8 then
    icon = wezterm.nerdfonts.fa_hourglass_o
    color = color_workhours_over
  elseif hours_worked >= 7 then
    icon = wezterm.nerdfonts.fa_hourglass_o
    color = color_workhours_good
  elseif hours_worked >= 5 then
    icon = wezterm.nerdfonts.fa_hourglass_end
    color = color_workhours_end
  elseif hours_worked >= 2 then
    icon = wezterm.nerdfonts.fa_hourglass_half
    color = color_workhours_half
  end

  local hours_text = string.format("%.1f", hours_worked):gsub("%.0$", "")
  return icon, hours_text, color
end

local function left_status_bar_plugin(window, palette)
  local tab_colors = palette.tab_bar
  local leader_icon = window:leader_is_active() and wezterm.nerdfonts.cod_circle_large_filled
    or wezterm.nerdfonts.cod_circle_large_outline
  local leader = wezterm.format({
    { Foreground = { Color = palette.background } },
    { Background = { Color = palette.ansi[5] } },
    { Text = " " .. leader_icon .. " " },
  })

  local mode = ""
  local kt = window:active_key_table()
  if kt and KEY_TABLE_LABELS[kt] then
    mode = wezterm.format({
      { Foreground = { Color = palette.background } },
      { Background = { Color = palette.ansi[5] } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. KEY_TABLE_LABELS[kt] },
      "ResetAttributes",
    })
  end

  local mux = window:mux_window()
  local first_active = false
  if mux then
    local info = mux:tabs_with_info()
    first_active = info[1] and info[1].is_active or false
  end
  local divider_bg = first_active and palette.ansi[2] or tab_colors.inactive_tab.bg_color
  local divider = wezterm.format({
    { Background = { Color = divider_bg } },
    { Foreground = { Color = palette.ansi[5] } },
    { Text = DIV_R },
  })

  local workspace = wezterm.format({
    { Foreground = { Color = theme.tab_bar.active_fg } },
    { Background = { Color = theme.base.bg } },
    { Text = "  " .. window:active_workspace() .. " " },
  })

  return leader .. mode .. divider .. workspace
end

local function build_right_status(window)
  local waiting_count = 0
  local init_notice = agent_deck.consume_init_notice and agent_deck.consume_init_notice() or nil
  if init_notice then
    window:toast_notification("Agent Deck", init_notice, nil, 2500)
  end

  if agent_deck then
    local mux_window = window:mux_window()
    if mux_window then
      for _, tab in ipairs(mux_window:tabs()) do
        for _, pane in ipairs(tab:panes()) do
          agent_deck.update_pane(pane)
        end
      end
    end

    waiting_count = agent_deck.count_waiting()
  end

  local date = wezterm.strftime("(%Y-%m-%d) %a %b %-d ")
  local time = wezterm.strftime("%I:%M")
  local week_number = os.date("%V")
  local workhours_icon, workhours_text, workhours_color = get_workhours_display(window)

  -- Reset and reuse the status table
  status = {
    { Foreground = color_waiting },
    { Text = waiting_count > 0 and ("◔ " .. waiting_count .. " ") or "" },
    { Foreground = color_separator },
    { Text = waiting_count > 0 and "▏" or "" },
    { Foreground = color_gray },
    { Text = date },
    { Foreground = color_separator },
    { Text = "▏" },
    { Foreground = color_gray },
    { Text = wezterm.nerdfonts.cod_calendar .. " " .. tonumber(week_number) },
    { Foreground = color_separator },
    { Text = " ▏" },
    { Foreground = color_white },
    { Text = time },
    { Foreground = color_separator },
    { Text = "▕" },
  }

  if workhours_icon and workhours_text and workhours_color then
    table.insert(status, { Text = " " })
    table.insert(status, { Foreground = workhours_color })
    table.insert(status, { Text = workhours_icon .. " " .. workhours_text .. " " })
  end

  return status
end

local function update_status(window)
  local ok, conf = pcall(window.effective_config, window)
  if ok and conf then
    window:set_left_status(left_status_bar_plugin(window, conf.resolved_palette))
  else
    window:set_left_status(" " .. window:active_workspace() .. " ")
  end

  window:set_right_status(wezterm.format(build_right_status(window)))
end

return function()
  if not is_windows then
    wezterm.on("update-status", update_status)
  end
end
