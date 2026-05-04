local wezterm = require("wezterm")
local act = wezterm.action
local path_utils = require("lua.utils.path")

local M = {}

M.spawn_tab_with = function(window, spec)
  local new_tab, new_pane = window:mux_window():spawn_tab({
    args = path_utils.shell_args(),
  })

  new_tab:set_title(spec.title or spec.label)

  local cwd = expand_path(spec.cwd)
  if cwd then
    new_pane:send_text("cd " .. cwd .. "\n")
  end

  if spec.cmds then
    for i, cmd in ipairs(spec.cmds) do
      local is_last = (i == #spec.cmds)
      local suspend = is_last and spec.suspend_last
      new_pane:send_text(cmd .. (suspend and "" or "\n"))
    end
  end

  return new_tab, new_pane
end

M.toggle_tab_with_cmd = function(window, pane, tab_name, cmds)
  for _, tab in ipairs(window:mux_window():tabs_with_info()) do
    if tab.tab:get_title() == tab_name then
      if tab.is_active then
        window:perform_action(act.ActivateLastTab, pane)
      else
        tab.tab:activate()
      end
      return
    end
  end

  local new_tab, new_pane = window:mux_window():spawn_tab({
    args = path_utils.shell_args(true),
    cwd = pane:get_current_working_dir(),
  })

  new_tab:set_title(tab_name)

  -- send commands (avoiding quoting issues)
  if cmds then
    for _, c in ipairs(cmds) do
      new_pane:send_text(c .. "\n")
    end
  end
end

M.get_active_tab_index = function(window)
  for _, item in ipairs(window:mux_window():tabs_with_info()) do
    if item.is_active then
      return item.index
    end
  end

  return 0
end

M.create_tab = function(window, pane)
  local mux_window = window:mux_window()
  local current_index = M.get_active_tab_index(window)
  mux_window:spawn_tab({})
  window:perform_action(act.MoveTab(current_index + 1), pane)
end

return M
