local uv = vim.uv or vim.loop

local markers = {
  ".git",
  "package.json",
  "Cargo.toml",
  "go.mod",
  "pyproject.toml",
  "Makefile",
  "Gemfile",
  "requirements.txt",
}

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

local function dirname(path)
  return vim.fn.fnamemodify(path, ":h")
end

local function find_root(start)
  local dir = vim.fn.fnamemodify(start, ":p:h")

  while dir and dir ~= "/" do
    for _, marker in ipairs(markers) do
      if exists(dir .. "/" .. marker) then
        return dir
      end
    end
    dir = dirname(dir)
  end

  return vim.fn.getcwd()
end

local M = {}

function M.get()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.fn.getcwd()
  end

  return find_root(file)
end

return M