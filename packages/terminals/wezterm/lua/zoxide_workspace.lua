--- Zoxide-backed directory choices for workspace switching (plugin-style helpers).
--- Used by lua.projects; does not duplicate mux workspace listing or stack logic.

local wezterm = require("wezterm")

local M = {}

M.zoxide_path = "zoxide"

local is_windows = string.find(wezterm.target_triple, "windows") ~= nil

---@param cmd string
---@return string
function M.run_child_process(cmd)
  local shell = os.getenv("SHELL")
  local process_args = { shell or "/bin/sh", "-c", cmd }
  if is_windows then
    process_args = { "cmd", "/c", cmd }
  end
  local success, stdout, stderr = wezterm.run_child_process(process_args)
  if not success then
    wezterm.log_error("Child process '" .. cmd .. "' failed with stderr: '" .. tostring(stderr) .. "'")
  end
  return stdout or ""
end

---@param path string
---@return string
function M.path_to_tilde(path)
  return string.gsub(path, wezterm.home_dir, "~")
end

--- Append zoxide `query -l` paths as InputSelector rows with id prefix `zoxide:`.
--- skip_paths: absolute path -> true omits that path and avoids duplicate rows.
---@param choices { id: string, label: string }[]
---@param skip_paths table<string, boolean>|nil
---@param extra_args string|nil extra CLI args for `zoxide query -l`
function M.append_query_choices(choices, skip_paths, extra_args)
  skip_paths = skip_paths or {}
  extra_args = extra_args or ""

  local stdout = M.run_child_process(M.zoxide_path .. " query -l " .. extra_args)
  for _, path in ipairs(wezterm.split_by_newlines(stdout)) do
    if path ~= "" and not skip_paths[path] then
      skip_paths[path] = true
      local tilde = M.path_to_tilde(path)
      table.insert(choices, {
        id = "zoxide:" .. path,
        label = "⌁ " .. tilde,
      })
    end
  end
end

--- Bump rank after spawning from zoxide (matches common smart-switcher behavior).
---@param path string
function M.record_visit(path)
  M.run_child_process(M.zoxide_path .. " add " .. path)
end

return M
