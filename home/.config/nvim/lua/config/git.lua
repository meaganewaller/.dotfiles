local map = vim.keymap.set

--------------------------------------------------
-- Show git status
--------------------------------------------------

local function show_git_status()
  local status = vim.fn.systemlist("git status --porcelain")

  if #status == 0 then
    vim.api.nvim_echo(
      { { "Git status: working tree clean", "WarningMsg" } },
      false,
      {}
    )
  else
    vim.cmd("G")
  end
end

map("n", "<leader>gs", show_git_status, { silent = true })

--------------------------------------------------
-- Git helpers
--------------------------------------------------

map("n", "<leader>gff", function()
  print("Git fetching...")
  vim.cmd("G fetch")
end)

map("n", "<leader>gpl", function()
  print("Git pulling...")
  vim.cmd("G pull")
end)

map("n", "<leader>gps", function()
  print("Git pushing...")
  vim.cmd("G push")
end)

map("n", "<leader>gcm", ":G commit -m ")

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" }, { confirm = false })

local solid_bar = "│"
local dashed_bar = "┊"
require("gitsigns").setup({
  current_line_blame = true,
  signs = {
    add = { text = solid_bar },
    untracked = { text = solid_bar },
    change = { text = solid_bar },
    delete = { text = solid_bar },
    topdelete = { text = solid_bar },
    changedelete = { text = solid_bar },
  },
  signs_staged = {
    add = { text = dashed_bar },
    untracked = { text = dashed_bar },
    change = { text = dashed_bar },
    delete = { text = dashed_bar },
    topdelete = { text = dashed_bar },
    changedelete = { text = dashed_bar },
  },
})

-- stylua: ignore start
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "]h", function() require("gitsigns").nav_hunk("next") end, { remap = true, desc = "Git Next Hunk" })
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "[h", function() require("gitsigns").nav_hunk("prev") end, { remap = true, desc = "Git Prev Hunk" })
-- stylua: ignore end