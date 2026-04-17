vim.pack.add({
    { src = "https://github.com/scottmckendry/cyberdream.nvim", name = "cyberdream" },
}, { confirm = false })

require("cyberdream").setup({
  variant = "auto",
  transparent = true,
  italic_comments = true,
  hide_fillchars = true,
  terminal_colors = false,
  cache = true,
  borderless_pickers = true,
  overrides = function(c)
    return {
        CursorLine = { bg = c.bg },
        CursorLineNr = { fg = c.magenta },
    }
  end
})

vim.cmd("colorscheme cyberdream")
