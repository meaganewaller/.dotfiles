-- lua/tmux/send.lua -- tmux send-keys + pane discovery helpers
local M = {}

function M._quote_for_send_keys(s)
  -- For shell-level `'...'` wrapping: replace each ' with '\''
  return (s:gsub("'", "'\\''"))
end

function M._build_send_cmd(pane_id, payload)
  return { 'tmux', 'send-keys', '-t', pane_id, '-l', payload }
end

function M._build_enter_cmd(pane_id)
  return { 'tmux', 'send-keys', '-t', pane_id, 'Enter' }
end

function M.get_claude_pane_id()
  local result = vim
    .system({
      'tmux',
      'show-option',
      '-w',
      '-v',
      '-q',
      '@claude_pane_id',
    }, { text = true })
    :wait()
  if result.code ~= 0 then
    return nil
  end
  local id = (result.stdout or ''):gsub('%s+$', '')
  if id == '' then
    return nil
  end
  -- Verify pane is still alive
  local alive = vim.system({ 'tmux', 'list-panes', '-t', id }, { text = true }):wait()
  if alive.code ~= 0 then
    -- Stale; clear the option
    vim.system({ 'tmux', 'set-option', '-w', '-u', '@claude_pane_id' }):wait()
    return nil
  end
  return id
end

function M.set_claude_pane_id(id)
  vim.system({ 'tmux', 'set-option', '-w', '@claude_pane_id', id }):wait()
end

-- Resolve which Claude surface should receive sends. Priority:
-- 1. @claude_pane_id on the current nvim window (set by <leader>cc)
-- 2. claude tmux session's pane (set by <leader>cp)
-- 3. nil — caller should notify the user
function M.resolve_target()
  local id = M.get_claude_pane_id()
  if id then
    return id, 'pane'
  end
  local ok, popup = pcall(require, 'tmux.claude_popup')
  if ok then
    local pid = popup.pane_id()
    if pid then
      return pid, 'popup'
    end
  end
  return nil, nil
end

-- Map a pane id to its containing session name (e.g. '%42' -> 'cc-nvim').
function M._session_of_pane(pane_id)
  local res = vim
    .system({ 'tmux', 'display-message', '-p', '-t', pane_id, '#{session_name}' }, { text = true })
    :wait()
  if res.code ~= 0 then
    return nil
  end
  local name = (res.stdout or ''):gsub('%s+$', '')
  if name == '' then
    return nil
  end
  return name
end

function M.send_to_claude(payload)
  local id = M.resolve_target()
  if not id then
    vim.notify(
      'No Claude surface open. Press <leader>cc (pane) or <leader>cp (popup) first.',
      vim.log.levels.WARN
    )
    return false
  end
  if #payload > 10 * 1024 then
    local ok = vim.fn.confirm(
      string.format('Send %dKB to Claude pane?', math.floor(#payload / 1024)),
      '&Yes\n&No'
    ) == 1
    if not ok then
      return false
    end
  end
  vim.system(M._build_send_cmd(id, payload)):wait()
  vim.system(M._build_enter_cmd(id)):wait()
  -- Mark the containing session busy so idle watcher doesn't flip back
  -- to idle until output actually settles.
  local ok_idle, idle = pcall(require, 'tmux.idle')
  if ok_idle then
    local name = M._session_of_pane(id)
    if name then
      idle.mark_busy(name)
    end
  end
  return true
end

return M