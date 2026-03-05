local uv = vim.uv or vim.loop

local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
local cwd = git_root ~= "" and git_root or vim.fn.getcwd()
local project_vim_dir = cwd .. "/.vim"

local dirs = {
  undo = project_vim_dir .. "/undo",
  swap = project_vim_dir .. "/swap",
  backup = project_vim_dir .. "/backup",
}

-- create .vim directory if missing
if not uv.fs_stat(project_vim_dir) then
  vim.fn.mkdir(project_vim_dir)
end

-- create subdirectories
for _, dir in pairs(dirs) do
  if not uv.fs_stat(dir) then
    vim.fn.mkdir(dir, "p")
  end
end

-- configure vim
vim.opt.undofile = true
vim.opt.undodir = dirs.undo
vim.opt.directory = dirs.swap
vim.opt.backupdir = dirs.backup