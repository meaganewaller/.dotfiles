-- lua/tmux/claude.lua — <leader>c* commands
local M = {}
local send = require('tmux.send')

function M._build_cf_payload(rel_path)
  return '@' .. rel_path
end

function M._build_cs_payload(rel_path, lstart, lend, ft, lines)
  local content = table.concat(lines, '\n')
  local fence = content:find('```', 1, true) and '~~~' or '```'
  return string.format('@%s:%d-%d\n%s%s\n%s\n%s', rel_path, lstart, lend, fence, ft, content, fence)
end

local SEVERITY_NAMES = { 'ERROR', 'WARN', 'INFO', 'HINT' }

function M._build_ce_payload(rel_path, diags)
  local bullets = {}
  for _, d in ipairs(diags) do
    table.insert(
      bullets,
      string.format(
        '- %s: %s (line %d)',
        SEVERITY_NAMES[d.severity] or 'UNKNOWN',
        d.message,
        d.lnum + (d.lnum == 0 and 0 or 0)
      )
    )
  end
  return string.format('@%s\nDiagnostics:\n%s\n\nFix these.', rel_path, table.concat(bullets, '\n'))
end

local function buf_rel_path()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
end

function M.open()
  local id = send.get_claude_pane_id()
  if id then
    vim.system({ 'tmux', 'select-pane', '-t', id }):wait()
    return
  end
  local cwd = vim.fn.expand('%:p:h')
  local res = vim
    .system({
      'tmux',
      'split-window',
      '-h',
      '-c',
      cwd,
      '-P',
      '-F',
      '#{pane_id}',
      'claude',
    }, { text = true })
    :wait()
  if res.code == 0 then
    local new_id = (res.stdout or ''):gsub('%s+$', '')
    send.set_claude_pane_id(new_id)
  else
    vim.notify('failed to spawn Claude pane: ' .. (res.stderr or ''), vim.log.levels.ERROR)
  end
end

function M.send_file()
  send.send_to_claude(M._build_cf_payload(buf_rel_path()))
end

function M.send_selection()
  local lstart = vim.fn.getpos("'<")[2]
  local lend = vim.fn.getpos("'>")[2]
  local lines = vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
  local ft = vim.bo.filetype
  send.send_to_claude(M._build_cs_payload(buf_rel_path(), lstart, lend, ft, lines))
end

function M.send_errors()
  local diags = vim.diagnostic.get(0)
  send.send_to_claude(M._build_ce_payload(buf_rel_path(), diags))
end

-- Keymaps registered statically in lua/plugins/tmux.lua so which-key
-- sees them on <leader> before the module is loaded. Handlers notify
-- when called outside a tmux session instead of silently no-opping.
local function guard()
  if vim.env.TMUX == nil or vim.env.TMUX == '' then
    vim.notify('tmux integration requires $TMUX (run nvim inside tmux)', vim.log.levels.WARN)
    return false
  end
  return true
end

function M.setup() end

function M.open_guarded()
  if guard() then
    M.open()
  end
end

function M.open_fresh_guarded()
  if not guard() then
    return
  end
  -- Kill existing pane if registered for the current nvim window.
  -- `send` is already required at the top of this file.
  local id = send.get_claude_pane_id()
  if id then
    vim.system({ 'tmux', 'kill-pane', '-t', id }):wait()
    vim.system({ 'tmux', 'set-option', '-w', '-u', '@claude_pane_id' }):wait()
  end
  M.open()
end
function M.send_file_guarded()
  if guard() then
    M.send_file()
  end
end
function M.send_selection_guarded()
  if guard() then
    M.send_selection()
  end
end
function M.send_errors_guarded()
  if guard() then
    M.send_errors()
  end
end

return M