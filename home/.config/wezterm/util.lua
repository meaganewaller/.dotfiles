local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

-- ---------- small helpers ----------

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function file_exists(path)
  if not path or #path == 0 then
    return false
  end
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- cached lookups so we don't run `which` a million times
local exe_cache = {}

-- Try:
--  1) explicit env var (e.g. WEZTERM_NVIM)
--  2) absolute candidates
--  3) `which <name>` via wezterm.run_child_process
function M.find_exe(name, opts)
  opts = opts or {}
  local cache_key = name .. "|" .. (opts.env_var or "") .. "|" .. table.concat(opts.candidates or {}, ",")
  if exe_cache[cache_key] ~= nil then
    return exe_cache[cache_key]
  end

  -- 1) env override
  if opts.env_var then
    local env = os.getenv(opts.env_var)
    if env and #env > 0 then
      if file_exists(env) then
        exe_cache[cache_key] = env
        return env
      end
      -- if it's not absolute, try which
      local ok, out = pcall(wezterm.run_child_process, { "which", env })
      if ok and out and #out > 0 then
        local p = trim(out)
        if file_exists(p) then
          exe_cache[cache_key] = p
          return p
        end
      end
    end
  end

  -- 2) known absolute paths
  for _, p in ipairs(opts.candidates or {}) do
    if file_exists(p) then
      exe_cache[cache_key] = p
      return p
    end
  end

  -- 3) which <name>
  local ok, out = pcall(wezterm.run_child_process, { "which", name })
  if ok and out and #out > 0 then
    local p = trim(out)
    if file_exists(p) then
      exe_cache[cache_key] = p
      return p
    end
  end

  exe_cache[cache_key] = nil
  return nil
end

-- ---------- shell / editor detection ----------

function M.shell_path()
  local work_machine = os.getenv("WORK_MACHINE")

  if WORK_MACHINE == "true" then
    local shell = M.find_exe("zsh", {
      env_var = "WEZTERM_SHELL",
      candidates = {
        "/opt/homebrew/bin/zsh",
        "/usr/local/bin/zsh",
        "/usr/bin/zsh",
        "/bin/zsh",
        "/bin/bash",
      },
    })
  else
    local shell = M.find_exe("fish", {
      env_var = "WEZTERM_SHELL",
      candidates = {
        "/opt/homebrew/bin/fish",
        "/usr/local/bin/fish",
        "/usr/bin/fish",
        "/bin/fish",
        "/bin/zsh",
        "/bin/bash",
      },
    })
  end

  if shell then
    return shell
  end

  local sh = os.getenv("SHELL")
  if sh and #sh > 0 then
    return sh
  end

  return "/bin/bash"
end

function M.shell_args(login)
  local shell = M.shell_path()
  local args = { shell }
  -- fish: -l ; zsh/bash: -l works for shells too
  if login ~= false then
    table.insert(args, "-l")
  end
  return args
end

function M.nvim_path()
  return M.find_exe("nvim", {
    env_var = "WEZTERM_NVIM",
    candidates = {
      "/opt/homebrew/bin/nvim",
      "/usr/local/bin/nvim",
      "/usr/bin/nvim",
    },
  })
end

function M.vim_path()
  return M.find_exe("vim", {
    env_var = "WEZTERM_VIM",
    candidates = {
      "/opt/homebrew/bin/vim",
      "/usr/local/bin/vim",
      "/usr/bin/vim",
    },
  })
end

function M.editor_path()
  return M.nvim_path() or M.vim_path() or "vi"
end

-- ---------- your existing helpers (with safer spawn patterns) ----------

function M.get_cmd_out(cmd, raw)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))
  f:close()
  if raw then
    return s
  end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", " ")
  return s
end

function M.toggleTabWithCmd(window, pane, tabName, cmds)
  for _, tab in ipairs(window:mux_window():tabs_with_info()) do
    if tab.tab:get_title() == tabName then
      if tab.is_active then
        window:perform_action(act.ActivateLastTab, pane)
      else
        tab.tab:activate()
      end
      return
    end
  end

  local newTab, newPane = window:mux_window():spawn_tab({
    args = M.shell_args(true),
    cwd = pane:get_current_working_dir(),
  })
  newTab:set_title(tabName)

  -- send commands (avoids quoting nightmares)
  if cmds then
    for _, c in ipairs(cmds) do
      newPane:send_text(c .. "\n")
    end
  end
end

function M.get_active_tab_index(window)
  for _, item in ipairs(window:mux_window():tabs_with_info()) do
    if item.is_active then
      return item.index
    end
  end
  return 0
end

function M.openScrollbackInVIM(window, pane)
  local active_tab_index = M.get_active_tab_index(window)

  local text = pane:get_lines_as_escapes(pane:get_dimensions().scrollback_rows)
  local name = os.tmpname()
  local f = io.open(name, "w+")
  if not f then
    return
  end
  f:write(text)
  f:flush()
  f:close()

  local editor = M.editor_path()

  local newTab = window:mux_window():spawn_tab({
    args = {
      editor,
      "-u",
      "~/.config/nvim/init_as_pager.lua",
      "-c",
      "silent te cat " .. name .. "  - ",
      "-c",
      "normal G",
    },
    cwd = pane:get_current_working_dir(),
  })
  newTab:set_title("scrollback")

  window:perform_action(act.MoveTab(active_tab_index + 1), pane)

  wezterm.sleep_ms(1000)
  os.remove(name)
end

function M.createTab(window, pane)
  local mux_window = window:mux_window()
  local current_index = M.get_active_tab_index(window)
  mux_window:spawn_tab({})
  window:perform_action(act.MoveTab(current_index + 1), pane)
end

function M.basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.show_keymap(window, pane, title, lines)
  local choices = {}
  for i, line in ipairs(lines) do
    table.insert(choices, { id = tostring(i), label = line })
  end

  window:perform_action(
    act.InputSelector({
      title = title,
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(_, _, _, _)
        -- no-op: this is just a HUD
      end),
    }),
    pane
  )
end

return M
