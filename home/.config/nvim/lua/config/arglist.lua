local map = vim.keymap.set

map("n", "<leader>aa", function()
  vim.cmd("argadd %")
  vim.cmd("argdedupe")
  print("Added " .. vim.fn.expand("%") .. " to arglist")
end, { silent = true })

map("n", "<leader>ad", function()
  vim.cmd("argdelete %")
  print("Deleted " .. vim.fn.expand("%") .. " from arglist")
end, { silent = true })

map("n", "<leader>al", "<cmd>args<CR>", { silent = true })

map("n", "<leader>ar", function()
  vim.cmd(vim.v.count1 .. "argument")
end, { silent = true })

map("n", "]a", "<cmd>next<CR>", { silent = true })
map("n", "[a", "<cmd>previous<CR>", { silent = true })
