--- plugin: commands
--- quick command launcher for WezTerm

-- machine-specific commands can be added via:
-- 1. ~/.config/wezterm/commands/local.lua (not tracked in git)
-- 2. environment variables for common paths

local wezterm = require("wezterm")
local utils = require("lua.utils")

local M = {}

local default_choices = {
  {
    label = "nvim",
    title = "Neovim",
    cmds = { "nvim" },
  },
  {
    label = "vim-diff",
    title = "Vim Diff",
    cmds = {
      "nvim -c 'enew | vsplit | enew |' -c diffthis -c 'startinsert | wincmd h | startinsert'",
    },
  },
  {
    label = "htop",
    title = "HTOP",
    cmds = { "htop" },
  },
  {
    label = "dotfiles",
    title = "Dotfiles",
    cwd = "~/github/meaganewaller/.dotfiles",
  }
}

-- Try to load machine-specific commands from local config
local function load_local_commands()
  local local_path = wezterm.config_dir .. "/commands/local.lua"
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

M.get_choices = function()
  local all = ensure_choices()
  local cs = {}

  for i, choice in ipairs(all) do
    table.insert(cs, { label = choice.label, id = tostring(i) })
  end

  return cs
end

M.invoke_cb = function(window, pane, id)
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

M.spawn_tab_with = utils.tabs.spawn_tab_with
M.expand_path = utils.path.expand_path

return M