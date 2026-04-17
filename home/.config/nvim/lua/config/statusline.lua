-- ░▒▓ native statusline ▓▒░
-- inspired by xero's lualine config

-- Cyberdream palette (with fallbacks)
local function get_colors()
  local ok, cd_colors = pcall(require, "cyberdream.colors")
  if ok then
    local variant = vim.o.background == "light" and "light" or "default"
    return cd_colors[variant]
  end
  return {
    bg = "#16181a", bg_alt = "#1e2124", bg_highlight = "#3c4048",
    fg = "#ffffff", grey = "#7b8496", blue = "#5ea1ff",
    green = "#5eff6c", cyan = "#5ef1ff", red = "#ff6e5e",
    yellow = "#f1ff5e", magenta = "#ff5ef1", pink = "#ff5ea0",
    orange = "#ffbd5e", purple = "#bd5eff",
  }
end

-- Highlight groups
local function set_highlights()
  local c = get_colors()

  -- Mode blocks
  vim.api.nvim_set_hl(0, "StModeNormal",  { bg = c.blue,    fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StModeInsert",  { bg = c.green,   fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StModeVisual",  { bg = c.magenta, fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StModeReplace", { bg = c.red,     fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StModeCommand", { bg = c.yellow,  fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StModeTerminal",{ bg = c.cyan,    fg = c.bg, bold = true })

  -- Gradient separators (mode → git)
  vim.api.nvim_set_hl(0, "StSepNormal",  { fg = c.blue,    bg = c.purple })
  vim.api.nvim_set_hl(0, "StSepInsert",  { fg = c.green,   bg = c.purple })
  vim.api.nvim_set_hl(0, "StSepVisual",  { fg = c.magenta, bg = c.purple })
  vim.api.nvim_set_hl(0, "StSepReplace", { fg = c.red,     bg = c.purple })
  vim.api.nvim_set_hl(0, "StSepCommand", { fg = c.yellow,  bg = c.purple })
  vim.api.nvim_set_hl(0, "StSepTerminal",{ fg = c.cyan,    bg = c.purple })

  -- Git section
  vim.api.nvim_set_hl(0, "StGit",       { bg = c.purple, fg = c.bg, bold = true })
  vim.api.nvim_set_hl(0, "StGitSep",    { fg = c.purple, bg = c.bg_alt })

  -- File section
  vim.api.nvim_set_hl(0, "StFile",      { bg = c.bg_alt, fg = c.fg })
  vim.api.nvim_set_hl(0, "StFileMod",   { bg = c.bg_alt, fg = c.orange, bold = true })
  vim.api.nvim_set_hl(0, "StFileSep",   { fg = c.bg_alt, bg = "NONE" })

  -- Middle (transparent)
  vim.api.nvim_set_hl(0, "StMid",       { bg = "NONE", fg = c.grey })

  -- Diagnostics
  vim.api.nvim_set_hl(0, "StDiagError", { bg = "NONE", fg = c.red })
  vim.api.nvim_set_hl(0, "StDiagWarn",  { bg = "NONE", fg = c.orange })
  vim.api.nvim_set_hl(0, "StDiagInfo",  { bg = "NONE", fg = c.cyan })
  vim.api.nvim_set_hl(0, "StDiagHint",  { bg = "NONE", fg = c.green })

  -- LSP section
  vim.api.nvim_set_hl(0, "StLspSep",    { fg = c.bg_alt, bg = "NONE" })
  vim.api.nvim_set_hl(0, "StLsp",       { bg = c.bg_alt, fg = c.cyan })

  -- Position section
  vim.api.nvim_set_hl(0, "StPosSep",    { fg = c.pink, bg = c.bg_alt })
  vim.api.nvim_set_hl(0, "StPos",       { bg = c.pink, fg = c.bg, bold = true })

  -- Inactive
  vim.api.nvim_set_hl(0, "StInactive",    { bg = c.bg_alt, fg = c.grey })
  vim.api.nvim_set_hl(0, "StInactiveSep", { fg = c.bg_alt, bg = "NONE" })
end

set_highlights()

-- Mode definitions: { label, mode_hl, sep_hl }
local mode_map = {
  ["n"]     = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["no"]    = { "O-PEND",  "StModeNormal",  "StSepNormal" },
  ["nov"]   = { "O-PEND",  "StModeNormal",  "StSepNormal" },
  ["noV"]   = { "O-PEND",  "StModeNormal",  "StSepNormal" },
  ["no\22"] = { "O-PEND",  "StModeNormal",  "StSepNormal" },
  ["niI"]   = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["niR"]   = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["niV"]   = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["nt"]    = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["ntT"]   = { "NORMAL",  "StModeNormal",  "StSepNormal" },
  ["v"]     = { "VISUAL",  "StModeVisual",  "StSepVisual" },
  ["vs"]    = { "VISUAL",  "StModeVisual",  "StSepVisual" },
  ["V"]     = { "V-LINE",  "StModeVisual",  "StSepVisual" },
  ["Vs"]    = { "V-LINE",  "StModeVisual",  "StSepVisual" },
  ["\22"]   = { "V-BLCK",  "StModeVisual",  "StSepVisual" },
  ["\22s"]  = { "V-BLCK",  "StModeVisual",  "StSepVisual" },
  ["s"]     = { "SELECT",  "StModeVisual",  "StSepVisual" },
  ["S"]     = { "S-LINE",  "StModeVisual",  "StSepVisual" },
  ["\19"]   = { "S-BLCK",  "StModeVisual",  "StSepVisual" },
  ["i"]     = { "INSERT",  "StModeInsert",  "StSepInsert" },
  ["ic"]    = { "INSERT",  "StModeInsert",  "StSepInsert" },
  ["ix"]    = { "INSERT",  "StModeInsert",  "StSepInsert" },
  ["R"]     = { "REPLACE", "StModeReplace", "StSepReplace" },
  ["Rc"]    = { "REPLACE", "StModeReplace", "StSepReplace" },
  ["Rx"]    = { "REPLACE", "StModeReplace", "StSepReplace" },
  ["Rv"]    = { "V-REPL",  "StModeReplace", "StSepReplace" },
  ["Rvc"]   = { "V-REPL",  "StModeReplace", "StSepReplace" },
  ["Rvx"]   = { "V-REPL",  "StModeReplace", "StSepReplace" },
  ["c"]     = { "COMMAND", "StModeCommand", "StSepCommand" },
  ["cv"]    = { "EX",      "StModeCommand", "StSepCommand" },
  ["ce"]    = { "EX",      "StModeCommand", "StSepCommand" },
  ["r"]     = { "PROMPT",  "StModeNormal",  "StSepNormal" },
  ["rm"]    = { "MORE",    "StModeNormal",  "StSepNormal" },
  ["r?"]    = { "CONFIRM", "StModeNormal",  "StSepNormal" },
  ["!"]     = { "SHELL",   "StModeTerminal","StSepTerminal" },
  ["t"]     = { "TERM",    "StModeTerminal","StSepTerminal" },
}

-- Git branch (cached)
local git_branch = ""

local function update_git_branch()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then dir = vim.fn.getcwd() end
  local branch = vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --abbrev-ref HEAD 2>/dev/null")
  if vim.v.shell_error == 0 then
    git_branch = vim.trim(branch)
  else
    git_branch = ""
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, {
  group = vim.api.nvim_create_augroup("StatuslineGit", { clear = true }),
  callback = update_git_branch,
})

-- Diagnostics with nerd font icons
local function diagnostics()
  local counts = vim.diagnostic.count(0)
  local parts = {}

  local levels = {
    { vim.diagnostic.severity.ERROR, " ", "StDiagError" },
    { vim.diagnostic.severity.WARN,  " ", "StDiagWarn" },
    { vim.diagnostic.severity.INFO,  " ", "StDiagInfo" },
    { vim.diagnostic.severity.HINT,  "󰌵 ", "StDiagHint" },
  }

  for _, level in ipairs(levels) do
    local n = counts[level[1]] or 0
    if n > 0 then
      table.insert(parts, "%#" .. level[3] .. "#" .. level[2] .. n)
    end
  end

  if #parts == 0 then
    return ""
  end

  return " " .. table.concat(parts, " ") .. " "
end

-- LSP clients
local function lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return " " .. table.concat(names, ", ")
end

-- File modified/readonly symbols
local function file_flags()
  local flags = ""
  if vim.bo.modified then
    flags = flags .. "%#StFileMod# 󰶻 "
  end
  if vim.bo.readonly then
    flags = flags .. "%#StFileMod#  "
  end
  return flags
end

-- Main statusline
local function statusline()
  local mode_raw = vim.api.nvim_get_mode().mode
  local mode_info = mode_map[mode_raw] or { mode_raw, "StModeNormal", "StSepNormal" }
  local mode_label = mode_info[1]
  local mode_hl = mode_info[2]
  local sep_hl = mode_info[3]

  local parts = {}

  -- ░▒▓ MODE ▓▒░
  table.insert(parts, "%#" .. mode_hl .. "# " .. mode_label .. " ")

  -- Gradient separator: mode → git/file
  if git_branch ~= "" then
    table.insert(parts, "%#" .. sep_hl .. "#▓▒░")
    table.insert(parts, "%#StGit#  " .. git_branch .. " ")
    table.insert(parts, "%#StGitSep#▓▒░")
  else
    table.insert(parts, "%#" .. sep_hl .. "#▓▒░")
    -- Need a sep from mode color to bg_alt when no git
    -- Reuse StGitSep since it transitions to bg_alt
  end

  -- File
  table.insert(parts, "%#StFile# %t")
  table.insert(parts, file_flags())
  table.insert(parts, "%#StFileSep#▓▒░")

  -- Middle gap (transparent)
  table.insert(parts, "%#StMid#%=")

  -- Diagnostics (floating in the middle)
  table.insert(parts, diagnostics())

  table.insert(parts, "%=")

  -- Right side: ░▒▓ LSP ▓▒░ Position ░
  local lsp = lsp_clients()
  if lsp ~= "" then
    table.insert(parts, "%#StLspSep#░▒▓")
    table.insert(parts, "%#StLsp#" .. lsp .. " ")
  end

  table.insert(parts, "%#StPosSep#░▒▓")
  table.insert(parts, "%#StPos# %l:%c %p%% ")

  return table.concat(parts)
end

-- Inactive statusline
local function statusline_inactive()
  return "%#StInactiveSep#░▒▓%#StInactive# %t%m%r%=%l:%c %#StInactiveSep#▓▒░"
end

-- Expose globally
_G.Statusline = statusline
_G.StatuslineInactive = statusline_inactive

-- Set statusline
vim.o.statusline = "%!v:lua.Statusline()"

-- Active/inactive switching
local group = vim.api.nvim_create_augroup("Statusline", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  callback = function()
    vim.wo.statusline = "%!v:lua.Statusline()"
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = group,
  callback = function()
    vim.wo.statusline = "%!v:lua.StatuslineInactive()"
  end,
})

-- Refresh highlights on colorscheme change (recomputes from palette)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = set_highlights,
})
