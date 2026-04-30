local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local theme = require("lua.theme")
local utils = require("lua.utils")

local M = {}

-- ============================================
-- Project Workspace System
-- ============================================
M.projects_dir = wezterm.home_dir .. "/.config/wezterm/projects"

local prev_pos = 1
local stack = { "default" }
local stack_pos = 1

local function workspace_exists(name)
  for _, ws in ipairs(wezterm.mux.get_workspace_names()) do
    if ws == name then
      return true
    end
  end
  return false
end

local function stack_prune()
  local pruned = {}
  local new_pos = 1
  local new_prev = 1
  for i, name in ipairs(stack) do
    if workspace_exists(name) then
      table.insert(pruned, name)
      if i == stack_pos then
        new_pos = #pruned
      end
      if i == prev_pos then
        new_prev = #pruned
      end
    end
  end
  if #pruned == 0 then
    pruned = { "default" }
    new_pos = 1
    new_prev = 1
  end
  stack = pruned
  stack_pos = math.min(new_pos, #stack)
  prev_pos = math.min(new_prev, #stack)
end

-- Paths relative to projects_dir without .lua, e.g. "dotfiles", "onlooker/plugins"
local function discover_project_files(root)
  local entries = {}
  local cmd = "cd " .. utils.shell_single_quote(root) .. " && find . -type f -name '*.lua' 2>/dev/null"
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      local rel = line:match("^%./(.+)%.lua$")
      if rel then
        table.insert(entries, {
          relpath = rel,
          fullpath = root .. "/" .. rel .. ".lua",
        })
      end
    end
    handle:close()
  end
  table.sort(entries, function(a, b)
    return a.relpath < b.relpath
  end)
  return entries
end

-- Path under a section folder, e.g. "client › foo" for client/foo.lua under group "work".
local function format_under_section_suffix(suffix)
  if not suffix or suffix == "" then
    return "?"
  end
  return suffix:gsub("/", " › ")
end

local function load_projects()
  local projects = {}
  for _, entry in ipairs(discover_project_files(M.projects_dir)) do
    local ok, project = pcall(dofile, entry.fullpath)
    if ok and project and project.workspace then
      project.cwd = utils.expand_path(project.cwd)
      project._relpath = entry.relpath
      projects[project.workspace] = project
    end
  end
  return projects
end

local function get_active_workspaces()
  local active = {}
  for _, win in ipairs(mux.all_windows()) do
    active[win:get_workspace()] = true
  end
  return active
end

local function stack_insert()
  for i, _ in ipairs(stack) do
    if i > stack_pos then
      table.remove(stack, i)
    end
  end
  if wezterm.mux.get_active_workspace() ~= stack[stack_pos] then
    prev_pos = stack_pos
    table.insert(stack, wezterm.mux.get_active_workspace())
  end
  stack_pos = #stack
end

local function stack_log()
  wezterm.log_debug("stack: " .. table.concat(stack))
  wezterm.log_debug("stack_pos: " .. stack_pos)
  wezterm.log_info("workspace: " .. wezterm.mux.get_active_workspace())
end

wezterm.on("projects.workspace_switcher.chosen", stack_insert)
wezterm.on("projects.workspace_switcher.created", stack_insert)

wezterm.on("stack-default", function(window, pane)
  if wezterm.mux.get_active_workspace() ~= "default" then
    window:perform_action(
      act.Multiple({
        act.SwitchToWorkspace({ name = "default" }),
        act.EmitEvent("stack-insert"),
      }),
      pane
    )
  end
end)

wezterm.on("stack-log", function()
  stack_log()
end)

wezterm.on("stack-in", function(window, pane)
  stack_prune()
  if stack_pos < #stack then
    prev_pos = stack_pos
    stack_pos = stack_pos + 1
    window:perform_action(act.SwitchToWorkspace({ name = stack[stack_pos] }), pane)
  end
end)

wezterm.on("stack-insert", function()
  stack_insert()
end)

wezterm.on("stack-out", function(window, pane)
  stack_prune()
  if stack_pos ~= 1 then
    prev_pos = stack_pos
    stack_pos = stack_pos - 1
    window:perform_action(act.SwitchToWorkspace({ name = stack[stack_pos] }), pane)
  end
end)

wezterm.on("stack-prev", function(window, pane)
  stack_prune()
  if prev_pos >= 1 and prev_pos <= #stack then
    local target_pos = prev_pos
    prev_pos = stack_pos
    stack_pos = target_pos
    window:perform_action(act.SwitchToWorkspace({ name = stack[target_pos] }), pane)
  end
end)

wezterm.on("stack-switcher", function(window, pane)
  window:perform_action(M.switch_or_start_project(window, pane))
end)

function M.with_cache(dest)
  if dest == "default" then
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.EmitEvent("stack-default"), pane)
    end)
  elseif dest == "in" then
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.EmitEvent("stack-in"), pane)
    end)
  elseif dest == "out" then
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.EmitEvent("stack-out"), pane)
    end)
  elseif dest == "prev" then
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.EmitEvent("stack-prev"), pane)
    end)
  elseif dest == "switcher" then
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.EmitEvent("stack-switcher"), pane)
    end)
  else
    return wezterm.action_callback(function(window, pane)
      window:perform_action(act.Nop, pane)
    end)
  end
end

function M.build_project_choices()
  local projects = load_projects()
  local active = get_active_workspaces()

  local flat = {}
  local groups = {}

  for name, project in pairs(projects) do
    local rel = project._relpath
    local is_active = active[name] and true or false
    local entry = {
      name = name,
      project = project,
      is_active = is_active,
      sort_key = rel or name,
    }
    if rel and rel:find("/", 1, true) then
      local g = rel:match("^([^/]+)/")
      if g then
        groups[g] = groups[g] or {}
        table.insert(groups[g], entry)
      else
        table.insert(flat, entry)
      end
    else
      table.insert(flat, entry)
    end
  end

  local function cmp_entry(a, b)
    if a.is_active ~= b.is_active then
      return a.is_active
    end
    return a.sort_key < b.sort_key
  end

  table.sort(flat, cmp_entry)
  local group_names = {}
  for g in pairs(groups) do
    table.insert(group_names, g)
  end
  table.sort(group_names)
  for _, g in ipairs(group_names) do
    table.sort(groups[g], cmp_entry)
  end

  local choices = {}

  local adhoc_names = {}
  for name, _ in pairs(active) do
    if not projects[name] then
      table.insert(adhoc_names, name)
    end
  end
  table.sort(adhoc_names)
  for _, name in ipairs(adhoc_names) do
    table.insert(choices, {
      id = "workspace:" .. name,
      label = "● " .. name .. " (ad-hoc)",
    })
  end

  for _, entry in ipairs(flat) do
    local p = entry.project
    local status = entry.is_active and "● " or "○ "
    local vis = p._relpath or entry.name
    table.insert(choices, {
      id = "project:" .. entry.name,
      label = status .. vis .. " (" .. (p.cwd or "?") .. ")",
    })
  end

  local nested_indent = "   "
  for _, gname in ipairs(group_names) do
    table.insert(choices, {
      id = "section:" .. gname,
      label = gname,
    })
    for _, entry in ipairs(groups[gname]) do
      local p = entry.project
      local rel = p._relpath
      local suffix = rel and rel:sub(#gname + 2) or ""
      local status = entry.is_active and "● " or "○ "
      local vis = format_under_section_suffix(suffix)
      table.insert(choices, {
        id = "project:" .. entry.name,
        label = status .. nested_indent .. vis .. " (" .. (p.cwd or "?") .. ")",
      })
    end
  end

  return choices, projects
end

function M.setup_project_tabs(project)
  wezterm.time.call_after(0.3, function()
    local workspace_windows = {}
    for _, win in ipairs(mux.all_windows()) do
      if win:get_workspace() == project.workspace then
        table.insert(workspace_windows, win)
      end
    end

    if #workspace_windows == 0 then
      return
    end
    local mux_win = workspace_windows[1]

    local tabs = project.tabs or {}
    for i, tab_config in ipairs(tabs) do
      local tab, pane
      if i == 1 then
        tab = mux_win:active_tab()
        pane = tab:active_pane()
        if project.cwd then
          pane:send_text("cd " .. project.cwd .. "\n")
        end
      else
        tab, pane = mux_win:spawn_tab({ cwd = project.cwd })
        if project.cwd then
          pane:send_text("cd " .. project.cwd .. "\n")
        end
      end

      if tab_config.cmd then
        pane:send_text(tab_config.cmd .. "\n")
      end
    end

    local first_tab = mux_win:tabs()[1]
    if first_tab then
      first_tab:activate()
    end
  end)
end

function M.switch_or_start_project(window, pane, id)
  if id and id:match("^section:") then
    return
  end

  local ws_name = id:match("^workspace:(.+)$")
  if ws_name then
    window:perform_action(act.SwitchToWorkspace({ name = ws_name }), pane)
    return
  end

  local name = id:match("^project:(.+)$")
  if not name then
    return
  end

  local active = get_active_workspaces()
  local projects = load_projects()
  local project = projects[name]

  if active[name] then
    window:perform_action(act.SwitchToWorkspace({ name = name }), pane)
  else
    window:perform_action(
      act.SwitchToWorkspace({
        name = name,
        spawn = { cwd = project and project.cwd or wezterm.home_dir },
      }),
      pane
    )

    if project and project.tabs then
      M.setup_project_tabs(project)
    end
  end
end

set_workspace_formatter(function(label)
  return wezterm.format({
    { Attribute = { Italic = true } },
    { Foreground = { Color = theme.colors.hl_1 } },
    { Text = " " .. label },
  })
end)

return M
