local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Restore cursor position
autocmd("BufReadPost", {
  group = augroup("mew_restore_cursor", { clear = true }),
  callback = function()
    if vim.bo.filetype == "gitcommit" then
      return
    end

    local mark = vim.api.nvim_buf_get_mark(0, '"')[1]
    local last = vim.api.nvim_buf_line_count(0)

    if mark > 0 and mark <= last then
      vim.cmd('normal! g`"')
    end
  end,
})

-- Close special buffers with 'q'
local function close_special_buffer()
  if vim.fn.winnr("$") > 1 then
    local cur = vim.fn.winnr()
    vim.cmd("wincmd p")
    vim.cmd(cur .. "wincmd c")
  else
    vim.cmd("bdelete!")
  end
end

autocmd("FileType", {
  group = augroup("mew_close_with_q", { clear = true }),
  pattern = {
    "qf",
    "git",
    "help",
    "netrw",
    "fugitive",
    "nvim-pack",
    "fugitiveblame",
    "dap-*",
    "nvim-undotree",
  },
  callback = function()
    vim.bo.buflisted = false

    vim.keymap.set("n", "q", close_special_buffer, {
      buffer = true,
      silent = true,
      nowait = true,
    })
  end,
})

-- Reload file if changed outside vim
autocmd("FocusGained", {
  group = augroup("mew_checktime", { clear = true }),
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Resize splits automatically
autocmd("VimResized", {
  group = augroup("mew_resize_splits", { clear = true }),
  callback = function()
    vim.cmd("wincmd =")
  end,
})

-- Auto-create directory on save
autocmd("BufWritePre", {
  group = augroup("mew_auto_create_dir", { clear = true }),
  callback = function(args)
    local file = args.file

    -- Skip URLs
    if file:match("^%w%w+://") then
      return
    end

    local dir = vim.fn.fnamemodify(file, ":p:h")

    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- React to system theme changes
autocmd("User", {
  group = augroup("mew_dark_notify", { clear = true }),
    pattern = "DarkNotify",
    callback = function()
      local mode = vim.fn.system("dark-notify -e"):gsub("\n", "")

      if mode == "dark" then
        vim.cmd.colorscheme("catppuccin-mocha")
      else
        vim.cmd.colorscheme("catppuccin-latte")
      end
    end,
  }
)

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_on_yank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- Update root when you open a new file from another project
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    require("config.project_dirs")
  end
})

-- Open quickfix window when searching for symbols
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    group = augroup("mew_quickfix_cmd_post", { clear = true }),
    pattern = "lsp_symbols",
    callback = function()
      vim.cmd("copen")
      vim.cmd("wincmd p")
    end,
  }
)
