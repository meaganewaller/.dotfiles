local fn = vim.fn
local api = vim.api

local home = fn.expand("~")
local session_file = fn.stdpath("state") .. "/session.vim"

local disabled_dirs = {
  home,
  home .. "/Downloads",
  "/private/tmp",
}

local started_with_stdin = false
local skip_session = false

-- detect stdin start
api.nvim_create_autocmd("StdinReadPre", {
  callback = function()
    started_with_stdin = true
  end,
})

local function session_save()
  if skip_session then
    return
  end

  -- wipe unlisted buffers
  for _, buf in ipairs(fn.getbufinfo()) do
    if buf.listed == 0 and fn.bufexists(buf.bufnr) == 1 then
      vim.cmd("bwipeout! " .. buf.bufnr)
    end
  end

  -- ensure at least one real file buffer
  local valid = vim.tbl_filter(function(buf)
    return fn.getbufvar(buf.bufnr, "&buftype") == "" and fn.bufname(buf.bufnr) ~= ""
  end, fn.getbufinfo())

  if #valid < 1 then
    return
  end

  local dir = fn.fnamemodify(session_file, ":h")
  if fn.isdirectory(dir) == 0 then
    fn.mkdir(dir, "p")
  end

  vim.cmd("mks! " .. fn.fnameescape(session_file))
end

local function session_load()
  local cwd = fn.getcwd()

  for _, path in ipairs(disabled_dirs) do
    if path == cwd then
      skip_session = true
      return
    end
  end

  if fn.argc() == 0 and not started_with_stdin then
    if fn.filereadable(session_file) == 1 then
      vim.cmd("source " .. fn.fnameescape(session_file))
    end
  else
    skip_session = true
  end
end

api.nvim_create_autocmd("VimLeavePre", {
  callback = session_save,
})

api.nvim_create_autocmd("VimEnter", {
  callback = session_load,
})
