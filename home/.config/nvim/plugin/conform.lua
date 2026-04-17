vim.pack.add({
    "https://github.com/stevearc/conform.nvim",
}, { confirm = false })

vim.cmd.packadd("conform.nvim")

require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        yaml = { "yamlfmt" },
        javascript = { "biome" },
        typescript = { "biome" },
        ruby = { "standardrb" }
    },
    format_on_save = { timeout_ms = 500, lsp_fallback = true }
})

vim.keymap.set({ "n", "v" }, "<leader>lf", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format buffer" })