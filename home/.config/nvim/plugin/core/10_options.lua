-- stylua: ignore start

-- ---------------------------------------------------------------------------
-- Custom globals
-- ---------------------------------------------------------------------------

--- Centralized toggle for GitHub Copilot
--- Default is enabled, set to true to disable
Config.copilot_disable = false

-- ---------------------------------------------------------------------------
-- Global settings
-- ---------------------------------------------------------------------------

vim.g.mapleader        = " "
vim.g.maplocalleader   = " "

-- ---------------------------------------------------------------------------
-- General settings
-- ---------------------------------------------------------------------------

-- Indentation & Formatting
-- Use spaces instead of tabs with two-space indentation across the board.
-- `shiftround` ensures indentation snaps cleanly to multiples of `shiftwidth`.
-- `textwidth = 78` enforces a soft editorial limit on line length.
-- `formatlistpat` ensures that lists are properly formatted.
-- `formatoptions` ensures that the correct options are set for formatting.
-- `breakindentopt` ensures that the list characters are used to indent the lines that are wrapped.
-- `conceallevel` ensures that the list characters are not visible in the buffer.
vim.opt.expandtab      = true
vim.opt.shiftwidth     = 2
vim.opt.shiftround     = true
vim.opt.textwidth      = 78
vim.opt.formatlistpat  = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]
vim.opt.formatoptions  = "jcrql1nt"
vim.opt.breakindentopt = "list:-1"
vim.opt.conceallevel   = 2

-- Completion Behavior
-- Completion sources include:
-- - Current buffer (.): search for completions in the current buffer
-- - Word under cursor (w): search for completions in the word under the cursor
-- - Buffer words (b): search for completions in the words in the buffer
-- - Spelling suggestions (kspell): search for spelling suggestions
-- `completeopt = "menuone,noselect,fuzzy"` ensures the completion menu is displayed
-- with the best match highlighted and the list of completions is filtered as you type.
-- `wildmode = "longest:full,full"` ensures that the command-line completion is done in a smart way.
-- - `longest` completes the longest common prefix of the input and the options.
-- - `full` shows all matches and let the user choose.
vim.opt.complete       = '.,w,b,kspell'
vim.opt.completeopt    = "menuone,noselect,fuzzy"
vim.opt.wildmode       = "longest:full,full"

-- Confirmation Behavior
-- `confirm = true` ensures that the user is prompted before any destructive actions
-- such as saving or quitting.
vim.opt.confirm        = true

-- List Characters & Whitespace Visibility
-- Makes invisible characters like ellipses, tabs, trailing spaces, and newlines visible.
-- Non-breaking spaces are represented by a small circle.
-- Line overflow is represented by an ellipsis.
vim.opt.list           = true
vim.opt.listchars      = { extends="…", precedes="…", tab="  ", nbsp="␣" }
vim.opt.fillchars      = { fold="╌", diff="╱", eob=" " }

-- Search & Replace
-- Uses `ripgrep` for fast, accurate search results.
-- Output is formatted for seamless integration with quickfix and diagnostics.
vim.opt.grepformat     = "%f:%l:%c:%m"
vim.opt.grepprg        = "rg --vimgrep"

-- Spelling
-- Treats camelCase identifiers as multiple words
-- Improves spelling suggestions for technical terms.
vim.opt.spelloptions   = "camel"

-- Splits & Window Behavior
-- Cursor position is preserved when splitting windows.
-- Prevents disorienting jumps when rearranging layouts.
vim.opt.splitkeep      = "cursor"

-- Messages & Feedback
-- Reduces noisy messages and feedback to only the most important information.
-- Keeps important feedback while suppressing less useful messages.
vim.opt.shortmess      = "FOSWICaco"

-- UI Polish
-- Rounded borders everywhere for consistency.
-- Popup menus are capped in height to 10 lines.
-- Windows are allowed to shrink but not collapse into unusable sizes.
vim.opt.winborder      = "rounded"
vim.opt.pumborder      = "rounded"
vim.opt.pumheight      = 10
vim.opt.winminwidth    = 5

-- ---------------------------------------------------------------------------
-- Fold settings
-- Folding is powered by Treesitter, not indentation heuristics.
-- Folds are available, but not imposed, `foldlevel=99` ensures all folds are open.
-- Fold text is empty, so folded sections don't add visual clutter.
-- ---------------------------------------------------------------------------

vim.opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel      = 99
vim.opt.foldmethod     = "expr"
vim.opt.foldnestmax    = 10
vim.opt.foldtext       = ""

-- ---------------------------------------------------------------------------
-- Diagnostics
-- ---------------------------------------------------------------------------

local diagnostic_opts = {
  severity_sort = true,
  underline = false,
  update_in_insert = false,
  virtual_text = {
    current_line = true,
  },
}
MiniDeps.later(function() vim.diagnostic.config(diagnostic_opts) end)

-- stylua: ignore end
