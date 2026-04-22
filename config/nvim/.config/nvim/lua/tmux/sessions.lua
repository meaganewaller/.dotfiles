-- lua/tmux/sessions.lua -- enumerate multi-project Claude tmux sessions.
-- Every cc-<slug> session created by lua/tmux/claude_popup.lua surfaces
-- here for the <leader>cl picker.
local M = {}

local PREFIX = 'cc-'

-- Parse output of `tmux list-sessions -F '#{session_name}|#{session_created}|#{pane_id}'`.
-- Returns a list of { name, slug, created_ts, first_pane_id } tables.
-- Ignores sessions whose name does not start with the cc- prefix.
function M._parse_list(raw)
  local out = {}
  for line in (raw or ''):gmatch('[^\n]+') do
    local trimmed = line:match('^%s*(.-)%s*$')
    if trimmed ~= '' then
      local name, created, pane = trimmed:match('^([^|]+)|([^|]+)|(.+)$')
      if name and name:sub(1, #PREFIX) == PREFIX then
        table.insert(out, {
          name = name,
          slug = name:sub(#PREFIX + 1),
          created_ts = tonumber(created) or 0,
          first_pane_id = pane,
        })
      end
    end
  end
  return out
end

-- Live query: returns the same shape as _parse_list on the active tmux server.
function M.list()
  local res = vim
    .system({
      'tmux',
      'list-sessions',
      '-F',
      '#{session_name}|#{session_created}|#{pane_id}',
    }, { text = true })
    :wait()
  if res.code ~= 0 then
    return {}
  end
  return M._parse_list(res.stdout or '')
end

return M