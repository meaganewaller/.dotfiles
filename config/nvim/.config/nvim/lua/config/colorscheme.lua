-- lua/config/colorscheme.lua -- Colorscheme for Neovim

local aug = vim.api.nvim_create_augroup('config.colorscheme', { clear = true })

vim.api.nvim_create_autocmd('ColorScheme', {
  group = aug,
  callback = function()
    -- Bump LineNr contrast
    vim.api.nvim_set_hl(0, 'LineNr', { fg = vim.api.nvim_get_hl_by_name('NonText', true).fg })
    vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = vim.api.nvim_get_hl_by_name('CursorLine', true).fg })

    -- Softer float borders
    vim.api.nvim_set_hl(0, 'FloatBorder', { fg = vim.api.nvim_get_hl_by_name('NonText', true).fg })
  end
})

vim.pack.add({
    { src = "https://github.com/scottmckendry/cyberdream.nvim", name = "cyberdream" },
    { src = "https://github.com/xero/evangelion.nvim" },
    { src = "https://github.com/xero/miasma.nvim" },
    { src = "https://github.com/xero/sourcerer.vim" },
    { src = "https://github.com/brenoprata10/nvim-highlight-colors" },
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

require('nvim-highlight-colors').setup({})

vim.cmd("colorscheme cyberdream")
