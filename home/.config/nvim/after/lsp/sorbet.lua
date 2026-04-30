return {
  cmd = { "srb", "tc", "--lsp" },
  filetypes = { "ruby" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, "sorbet/")
    if root then
      on_dir(root)
    end
  end,
}
