---@brief
--- https://biomejs.dev
---
--- Toolchain of the web. [Successor of Rome](https://biomejs.dev/blog/annoucing-biome).
---
--- ```sh
--- npm install [-g] @biomejs/biome
--- ```

return {
  cmd = function(_, config)
    local cmd = 'biome'
    local root_dir = config and config.root_dir or vim.fn.getcwd()
    local local_cmd = root_dir .. '/node_modules/.bin/biome'
    if vim.fn.executable(local_cmd) == 1 then
      cmd = local_cmd
    end
    return { cmd, 'lsp-proxy' }
  end,
  filetypes = {
    'astro', 'css', 'graphql', 'html', 'javascript', 'javascriptreact',
    'json', 'jsonc', 'svelte', 'typescript', 'typescript.tsx', 'typescriptreact', 'vue',
  },
  workspace_required = true,
  root_dir = function(bufnr)
    -- To support monorepos, biome recommends starting the search for the root from cwd
    -- https://biomejs.dev/guides/big-projects/#use-multiple-configuration-files
    local cwd = vim.fn.getcwd()
    local root_files = { 'biome.json', 'biome.jsonc' }
    local pkg_path = vim.fs.find('package.json', { path = cwd, upward = true })[1]
    if pkg_path then
      local pkg = vim.fn.json_decode(vim.fn.readfile(pkg_path))
      if (pkg.dependencies and pkg.dependencies.biome) or (pkg.devDependencies and pkg.devDependencies.biome) then
        table.insert(root_files, pkg_path)
      end
    end
    return vim.fs.dirname(vim.fs.find(root_files, { path = cwd, upward = true })[1])
  end,
}
