-- lua/coach/tips.lua -- Tips for Neovim

return {
    -- text-objects
    { keys = 'ciw', desc = 'change inside word', category = 'text-objects' },
    { keys = 'ci"', desc = 'change inside double quotes', category = 'text-objects' },
    { keys = "ci'", desc = 'change inside single quotes', category = 'text-objects' },
    { keys = 'ci(', desc = 'change inside parens', category = 'text-objects' },
    { keys = 'ci[', desc = 'change inside brackets', category = 'text-objects' },
    { keys = 'ci{', desc = 'change inside braces', category = 'text-objects' },
    { keys = 'cit', desc = 'change inside XML/HTML tag', category = 'text-objects' },
    { keys = 'dap', desc = 'delete a paragraph (with trailing blank)', category = 'text-objects' },
    { keys = 'vip', desc = 'visual-select inside paragraph', category = 'text-objects' },
    { keys = 'daf', desc = 'delete a function (treesitter)', category = 'text-objects' },
    -- motions
    { keys = 'f<char>', desc = 'jump forward to next <char> on line', category = 'motions' },
    { keys = 'F<char>', desc = 'jump backward to <char> on line', category = 'motions' },
    { keys = 't<char>', desc = 'jump to just-before <char> on line', category = 'motions' },
    { keys = '%', desc = 'jump to matching (/)/[/]/{/}', category = 'motions' },
    { keys = 'gg / G', desc = 'jump to file top / bottom', category = 'motions' },
      -- macros
  { keys = 'qa...q', desc = 'record macro into register a (q again to stop)', category = 'macros' },
  { keys = '@a', desc = 'replay macro a', category = 'macros' },
  { keys = '@@', desc = 'replay the last macro', category = 'macros' },
  { keys = '10@a', desc = 'replay macro a ten times', category = 'macros' },
  -- marks
  { keys = "ma / 'a", desc = 'set mark a / jump to line of mark a', category = 'marks' },
  { keys = "mA / 'A", desc = 'set global mark A (cross-file) / jump', category = 'marks' },
  { keys = "''", desc = 'jump back to previous position', category = 'marks' },
  -- registers
  { keys = '"ayy', desc = 'yank line into register a', category = 'registers' },
  { keys = '"+y', desc = 'yank into system clipboard', category = 'registers' },
  { keys = ':reg', desc = 'list all registers', category = 'registers' },
  -- search
  { keys = '*', desc = 'search forward for word under cursor', category = 'search' },
  { keys = 'n / N', desc = 'next / prev search match', category = 'search' },
  -- window
  { keys = '<C-w>v', desc = 'split window vertical', category = 'window' },
  { keys = '<C-w>=', desc = 'balance all splits', category = 'window' },
  -- lsp
  { keys = 'gd', desc = 'LSP: goto definition', category = 'lsp' },
  { keys = 'K', desc = 'LSP: hover docs', category = 'lsp' },
  { keys = '<leader>la', desc = 'LSP: code action', category = 'lsp' },
}