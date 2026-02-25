-- commands.lua
-- Quick command launcher for WezTerm
--
-- Machine-specific commands can be added via:
--   1. ~/.config/wezterm/commands.local.lua (not tracked in git)
--   2. Environment variables for common paths
--
local wezterm = require("wezterm")
local util = require("util")

local M = {}

-- Helper to expand environment variables and ~ in paths
local function expand_path(path)
  if not path then return nil end
  -- Expand ~
  path = path:gsub("^~", wezterm.home_dir)
  -- Expand $VAR and ${VAR}
  path = path:gsub("%$(%w+)", os.getenv)
  path = path:gsub("%${(%w+)}", os.getenv)
  return path
end

local function spawn_tab_with(window, spec)
  local newTab, newPane = window:mux_window():spawn_tab({
    args = util.shell_args(),
  })

  newTab:set_title(spec.title or spec.label)

  local cwd = expand_path(spec.cwd)
  if cwd then
    newPane:send_text("cd " .. cwd .. "\n")
  end

  if spec.cmds then
    for i, cmd in ipairs(spec.cmds) do
      local is_last = (i == #spec.cmds)
      local suspend = is_last and spec.suspend_last
      newPane:send_text(cmd .. (suspend and "" or "\n"))
    end
  end

  return newTab, newPane
end

-- Default commands (portable, work everywhere)
local default_choices = {
  {
    label = "nvim",
    title = "nvim",
    cmds = { "nvim" },
  },
  {
    label = "vim-diff",
    title = "vim-diff",
    cmds = {
      "nvim -c 'enew | vsplit | enew |' -c diffthis -c 'startinsert | wincmd h | startinsert'",
    },
  },
  {
    label = "htop",
    title = "htop",
    cmds = { "htop" },
  },
  {
    label = "dotfiles",
    title = "dotfiles",
    cwd = "~/.dotfiles",
  },
}

-- Try to load machine-specific commands from local config
local function load_local_commands()
  local local_path = wezterm.config_dir .. "/commands.local.lua"
  local ok, local_commands = pcall(dofile, local_path)
  if ok and type(local_commands) == "table" then
    return local_commands
  end
  return {}
end

-- Merge default and local commands
local function get_all_choices()
  local choices = {}

  -- Add defaults
  for _, choice in ipairs(default_choices) do
    table.insert(choices, choice)
  end

  -- Add local commands
  for _, choice in ipairs(load_local_commands()) do
    table.insert(choices, choice)
  end

  return choices
end

-- Cache the merged choices
local choices = nil
local function ensure_choices()
  if choices == nil then
    choices = get_all_choices()
  end
  return choices
end

function M.get_choices()
  local all = ensure_choices()
  local cs = {}
  for i, choice in ipairs(all) do
    table.insert(cs, { label = choice.label, id = tostring(i) })
  end
  return cs
end

function M.invoke_cb(window, pane, id)
  local all = ensure_choices()
  local choice = all[tonumber(id)]
  if not choice then
    return
  end

  if choice.cb then
    choice.cb(window, pane)
  else
    spawn_tab_with(window, choice)
  end
end

-- Export spawn_tab_with for use in local commands
M.spawn_tab_with = spawn_tab_with
M.expand_path = expand_path

return M
