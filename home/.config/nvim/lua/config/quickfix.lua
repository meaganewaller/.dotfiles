vim.cmd("packadd! cfilter")

local function toggle_quickfix()
  local winid = vim.fn.getqflist({ winid = 1 }).winid

  if winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen | cc")
  end
end

vim.keymap.set(
  "n",
  "<leader>qq",
  toggle_quickfix,
  { silent = true }
)