-- lua/remote/hosts.lua
local M = {}

local DB_PATH = vim.fn.stdpath('data') .. '/nvim/hosts.json'

function M._score(entry, now)
  local days_since = (now - entry.last_used) / 86400
  return entry.visits * math.exp(-days_since / 14)
end

function M._read_db()
  local f = io.open(DB_PATH, 'r')
  if not f then
    return {}
  end
  local raw = f:read('*a')
  f:close()
  local ok, db = pcall(vim.json.decode, raw)
  if not ok then
    vim.fn.delete(DB_PATH)
    return {}
  end
  return db or {}
end

function M._parse_ssh_config()
  local path = vim.fn.expand('~/.ssh/config')
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local hosts = {}
  for line in io.lines(path) do
    local h = line:match('^%s*[Hh]ost%s+(.+)$')
    if h then
      for part in h:gmatch('%S+') do
        if not part:find('[*?]') then
          table.insert(hosts, part)
        end
      end
    end
  end
  return hosts
end

function M._merge(db, config_hosts, now)
  local seen = {}
  local out = {}
  for host, entry in pairs(db) do
    table.insert(out, { host = host, score = M._score(entry, now) })
    seen[host] = true
  end
  for _, host in ipairs(config_hosts) do
    if not seen[host] then
      table.insert(out, { host = host, score = 0 })
    end
  end
  table.sort(out, function(a, b)
    return a.score > b.score
  end)
  return out
end

function M.pick()
  local db = M._read_db()
  local cfg = M._parse_ssh_config()
  local merged = M._merge(db, cfg, os.time())
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'ssh host',
      finder = finders.new_table({
        results = merged,
        entry_maker = function(h)
          return {
            value = h.host,
            display = string.format('%-30s  %6.2f', h.host, h.score),
            ordinal = h.host,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          actions.close(bufnr)
          local sel = action_state.get_selected_entry()
          if not sel then
            return
          end
          local mosh = vim.fn.executable('mosh') == 1 and 'mosh' or 'ssh'
          vim.system({ 'tmux', 'new-window', mosh .. ' ' .. sel.value }):wait()
        end)
        return true
      end,
    })
    :find()
end

function M.prune()
  local db = M._read_db()
  local pruned = 0
  for host, _ in pairs(db) do
    local res = vim.system({ 'getent', 'hosts', host }, { text = true }):wait()
    if res.code ~= 0 then
      db[host] = nil
      pruned = pruned + 1
    end
  end
  vim.fn.mkdir(vim.fn.stdpath('data') .. '/nvim', 'p')
  local f = io.open(DB_PATH, 'w')
  if f then
    f:write(vim.json.encode(db))
    f:close()
  end
  vim.notify(string.format('pruned %d unresolvable hosts', pruned))
end

-- Keymaps + :HostsPrune registered statically in lua/plugins/remote.lua.
function M.setup() end

return M