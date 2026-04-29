local function create_hs_config()
  local hs_version = vim.fn.system("hs -c _VERSION"):gsub("[\n\r]", "")
  local hs_path = vim.split(vim.fn.system("hs -c package.path"):gsub("[\n\r]", ""), ";")

  return {
    settings = {
      Lua = {
        runtime = {
          version = hs_version,
          path = hs_path,
        },
        diagnostics = { globals = { "hs" } },
        workspace = {
          library = {
            string.format("%s/.config/hammerspoon/Spoons/EmmyLua.spoon/annotations", os.getenv("HOME")),
          },
        },
        telemetry = {
          enable = false,
        },
      },
    },
  }
end

---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
  on_attach = function(client)
    if not client.workspace_folders or #client.workspace_folders == 0 then
      return
    end

    local path = client.workspace_folders[1].name

    if string.match(path, ".hammerspoon") then
      client.config.settings = create_hs_config()
    end
  end,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        -- ignoreDir is set in .luarc.json (lazydev overwrites LSP settings)
      },
      codeLens = { enable = false }, -- causes annoying flickering
      completion = { callSnippet = "Replace" },
      doc = { privateName = { "^_" } },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
      format = { enable = false }, -- use stylua via conform
    },
  },
}
