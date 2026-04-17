-- lua/remote/dirs.lua
local M = {}

local TTL = 7 * 86400
local CACHE_DIR = vim.fn.stdpath('data') .. '/nvim/remote-dirs'

function M._cache_path(host)
  return CACHE_DIR .. '/' .. host:gsub('[^%w_-]', '_') .. '.json'
end

function M._is_stale(entry, now)
  return (now - (entry.fetched_at or 0)) > TTL
end

function M._build_find_cmd(host)
  return {
    'ssh',
    host,
    [[find ~ -type d -maxdepth 6 -not -path '*/.*' -not -path '*/node_modules/*' 2>/dev/null]],
  }
end

function M._read_cache(host)
  local path = M._cache_path(host)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local raw = f:read('*a')
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if not ok then
    vim.fn.delete(path)
    return nil
  end
  return data
end

function M._write_cache(host, dirs)
  vim.fn.mkdir(CACHE_DIR, 'p')
  local f = io.open(M._cache_path(host), 'w')
  if not f then
    return
  end
  f:write(vim.json.encode({ fetched_at = os.time(), dirs = dirs }))
  f:close()
end

function M._fetch_sync(host)
  local res = vim.system(M._build_find_cmd(host), { text = true }):wait()
  if res.code ~= 0 then
    vim.notify('remote dir fetch failed: ' .. (res.stderr or ''), vim.log.levels.WARN)
    return {}
  end
  local dirs_list = {}
  for line in (res.stdout or ''):gmatch('[^\n]+') do
    table.insert(dirs_list, line)
  end
  return dirs_list
end

function M.pick_for_host(host)
  local entry = M._read_cache(host)
  local now = os.time()
  if entry == nil or M._is_stale(entry, now) then
    local fresh = M._fetch_sync(host)
    M._write_cache(host, fresh)
    entry = { fetched_at = now, dirs = fresh }
  end
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'remote dirs: ' .. host,
      finder = finders.new_table({ results = entry.dirs }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          actions.close(bufnr)
          local sel = action_state.get_selected_entry()
          if not sel then
            return
          end
          vim.system({ 'tmux', 'send-keys', '-l', 'cd ' .. sel[1] }):wait()
          vim.system({ 'tmux', 'send-keys', 'Enter' }):wait()
        end)
        return true
      end,
    })
    :find()
end

function M.pick()
  local host = vim.fn.input('Remote host: ')
  if host == '' then
    return
  end
  M.pick_for_host(host)
end

function M.refresh(host)
  host = host or vim.fn.input('Refresh dirs for host: ')
  if host == '' then
    return
  end
  local fresh = M._fetch_sync(host)
  M._write_cache(host, fresh)
  vim.notify(string.format('cached %d dirs for %s', #fresh, host))
end

function M.setup() end -- keymaps in lua/plugins/remote.lua

return M