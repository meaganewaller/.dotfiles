vim.pack.add({
    "https://github.com/saghen/blink.cmp",
    "https://github.com/L3MON4D3/LuaSnip",
}, { confirm = false })

vim.cmd.packadd("blink.cmp")
vim.cmd.packadd("LuaSnip")


require("blink.cmp").setup({
    keymap = { preset = 'default' },
    sources = {
        default = {
            'lsp',
            'path',
            'snippets',
            'buffer'
        },
    },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },
    snippets = { preset = 'luasnip' },
})