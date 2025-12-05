require("cyberdream").setup({
  variant = "auto",
  transparent = false,
  italic_comments = true,
  hide_fillchars = false,
  terminal_colors = true,
  cache = true,
  overrides = function(colors) -- NOTE: This function nullifies the `highlights` option
    -- Example:
    return {
      CursorLine = { bg = colors.bg },
      CursorLineNr = { fg = colors.magenta },
    }
  end,

  -- Override colors
  colors = {},

  -- Disable or enable colorscheme extensions
  extensions = {
    -- telescope = true,
    -- notify = true,
    -- mini = true,
  },
})

vim.cmd("colorscheme cyberdream")
