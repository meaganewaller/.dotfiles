local wezterm = require("wezterm")
local M = {}

--- Last path segment (works for / and \\).
---@param path string|nil
---@return string
function M.basename(path)
  if not path or path == "" then
    return path or ""
  end
  local s = path:gsub("[/\\]+$", "")
  local base = s:match("[^/\\]+$") or s
  return base
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function expand_path(path)
  if not path then return nil end
  path = path:gsub("^~", wezterm.home_dir)
  -- Expand $VAR and ${VAR}
  path = path:gsub("%$(%w+)", os.getenv)
  path = path:gsub("%${(%w+)}", os.getenv)
  return path
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

M.find_exe = function(name, opts)
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

M.is_windows = package.config:sub(0, 1) == "\\"
M.is_macos = wezterm.target_triple and wezterm.target_triple:find("apple%-darwin") ~= nil
M.is_linux = wezterm.target_triple and wezterm.target_triple:find("linux") ~= nil

M.shell_path = function()
  local fish = M.find_exe("fish", {
    env_var = "WEZTERM_SHELL",
    candidates = {
      "/opt/homebrew/bin/fish",
      "/usr/local/bin/fish",
      "/usr/bin/fish",
      "/bin/fish",
      "/bin/bash",
    },
  })

  local zsh = M.find_exe("zsh", {
    env_var = "WEZTERM_SHELL",
    candidates = {
      "/opt/homebrew/bin/zsh",
      "/usr/local/bin/zsh",
      "/usr/bin/zsh",
      "/bin/zsh",
    },
  })

  local bash = M.find_exe("bash", {
    env_var = "WEZTERM_SHELL",
    candidates = {
      "/bin/bash",
    },
  })

  if os.getenv("DOTFILES_PROFILE") == "work" then
    return zsh or bash
  else
    return fish or bash
  end
end

M.shell_args = function(login)
  local shell = M.shell_path()
  local args = { shell }

  -- fish: -l ; zsh/bash: -l works for shells too
  if login ~= false then
    table.insert(args, "-l")
  end
  return args
end

M.nvim_path = function()
  return M.find_exe("nvim", {
    env_var = "WEZTERM_NVIM", 
    candidates = {
      expand_path("~/.local/share/mise/shims/nvim"),
      "/opt/homebrew/bin/nvim",
      "/usr/local/bin/nvim",
      "/usr/bin/nvim",
    },
  })
end

M.vim_path = function()
  return M.find_exe("vim", {
    env_var = "WEZTERM_VIM",
    candidates = {
      "/opt/homebrew/bin/vim",
      "/usr/local/bin/vim",
      "/usr/bin/vim",
    },
  })
end

M.editor_path = function()
  return M.nvim_path() or M.vim_path() or "vi"
end

return M
