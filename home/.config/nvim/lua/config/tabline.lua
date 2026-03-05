-- highlight linking
vim.api.nvim_set_hl(0, "TabLineSel", { link = "PmenuSel" })

local function tabline()
  local line = ""

  local current = vim.fn.tabpagenr()
  local total = vim.fn.tabpagenr("$")

  for i = 1, total do
    if i == current then
      line = line .. "%#TabLineSel#"
    else
      line = line .. "%#TabLineNormal#"
    end

    local win = vim.fn.tabpagewinnr(i)
    local buflist = vim.fn.tabpagebuflist(i)
    local bufnr = buflist[win]
    local bufname = vim.fn.bufname(bufnr)
    local filetype = vim.bo[bufnr].filetype
    local filename = vim.fn.fnamemodify(bufname, ":t")

    if filename == "" then
      if filetype == "snacks_picker_list" then
        filename = "Snacks"
      elseif filetype == "checkhealth" then
        filename = "Health"
      else
        filename = "[No Name]"
      end
    end

    if i == current then
      line = line .. "▎" .. i .. ": " .. filename .. " "
    else
      local cwd = vim.fn.fnamemodify(vim.fn.getcwd(win, i), ":t")
      line = line .. " " .. i .. ": " .. cwd .. " "
    end
  end

  line = line .. "%#TabLineFill#%T"

  return line
end

-- register tabline
vim.o.tabline = "%!v:lua.TabLine()"

-- expose global function for tabline
_G.TabLine = tabline

-- highlight reload on colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("TablineHighlights", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "TabLineSel", { link = "PmenuSel" })
  end,
})

-- keymaps
local map = vim.keymap.set
local silent = { silent = true }

map("n", "<leader><tab>d", "<cmd>tabclose<CR>", silent)
map("n", "<leader><tab>D", "<cmd>tabonly<CR>", silent)
map("n", "<leader><tab>c", "<cmd>tabnew<CR>", silent)
map("n", "]<tab>", "<cmd>tabnext<CR>", silent)
map("n", "[<tab>", "<cmd>tabprevious<CR>", silent)

map("n", "<Tab>", function()
  if vim.v.count > 0 then
    vim.cmd("tabn " .. vim.v.count)
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })