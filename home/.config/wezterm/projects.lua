-- projects.lua
-- Project workspace launcher for WezTerm
--
-- Machine-specific projects can be added via:
--   ~/.config/wezterm/projects.local.lua (not tracked in git)
--
local wezterm = require("wezterm")
local util = require("util")

local M = {}

-- Helper to expand environment variables and ~ in paths
local function expand_path(path)
  if not path then
    return nil
  end
  path = path:gsub("^~", wezterm.home_dir)
  path = path:gsub("%$(%w+)", os.getenv)
  path = path:gsub("%${(%w+)}", os.getenv)
  return path
end

-- Default projects (portable, work everywhere)
local default_projects = {
  {
    name = "dotfiles",
    path = "~/.dotfiles",
    icon = "󰣖",
  },
}

-- Try to load machine-specific projects from local config
local function load_local_projects()
  local local_path = wezterm.config_dir .. "/projects.local.lua"
  local ok, local_projects = pcall(dofile, local_path)
  if ok and type(local_projects) == "table" then
    return local_projects
  end
  return {}
end

-- Merge default and local projects
local function get_all_projects()
  local projects = {}

  for _, project in ipairs(default_projects) do
    table.insert(projects, project)
  end

  for _, project in ipairs(load_local_projects()) do
    table.insert(projects, project)
  end

  return projects
end

-- Cache the merged projects
local projects_cache = nil
local function ensure_projects()
  if projects_cache == nil then
    projects_cache = get_all_projects()
  end
  return projects_cache
end

-- Get choices for InputSelector
function M.get_choices()
  local all = ensure_projects()
  local choices = {}
  for i, project in ipairs(all) do
    local icon = project.icon or "󰉋"
    table.insert(choices, {
      id = tostring(i),
      label = icon .. "  " .. project.name,
    })
  end
  return choices
end

-- Check if a workspace exists
local function workspace_exists(name)
  for _, ws in ipairs(wezterm.mux.get_workspace_names()) do
    if ws == name then
      return true
    end
  end
  return false
end

-- Switch to or create a project workspace
function M.switch_to_project(window, pane, project)
  local cwd = expand_path(project.path)

  if workspace_exists(project.name) then
    -- Workspace exists, just switch to it
    window:perform_action(
      wezterm.action.SwitchToWorkspace({ name = project.name }),
      pane
    )
  else
    -- Create new workspace with project directory
    window:perform_action(
      wezterm.action.SwitchToWorkspace({
        name = project.name,
        spawn = {
          cwd = cwd,
          args = util.shell_args(true),
        },
      }),
      pane
    )

    -- Run startup commands if defined
    if project.cmds then
      -- Small delay to ensure pane is ready
      wezterm.time.call_after(0.1, function()
        local new_pane = window:active_pane()
        if new_pane then
          for _, cmd in ipairs(project.cmds) do
            new_pane:send_text(cmd .. "\n")
          end
        end
      end)
    end
  end
end

-- Callback for InputSelector
function M.invoke_cb(window, pane, id)
  local all = ensure_projects()
  local project = all[tonumber(id)]
  if not project then
    return
  end

  M.switch_to_project(window, pane, project)
end

-- Create the picker action
function M.picker_action()
  return wezterm.action.InputSelector({
    fuzzy = true,
    title = "  Switch to Project Workspace",
    choices = M.get_choices(),
    action = wezterm.action_callback(function(window, pane, id, label)
      if id and label then
        M.invoke_cb(window, pane, id)
      end
    end),
  })
end

-- Export helpers for use in local projects
M.expand_path = expand_path

return M
