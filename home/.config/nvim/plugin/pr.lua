require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/fredrikaverpil/pr.nvim" },
  })

  require("pr").setup({})

  vim.keymap.set("n", "<leader>gbv", function()
    require("pr").view()
  end, { desc = "View PR in browser" })
end)
