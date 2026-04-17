-- lua/remote/browse.lua
local M = {}

local BINARY_EXTS = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  pdf = true,
  zip = true,
  tar = true,
  gz = true,
  xz = true,
  bz2 = true,
  exe = true,
  so = true,
  o = true,
  a = true,
  bin = true,
  mp4 = true,
  mov = true,
  mp3 = true,
  flac = true,
  woff = true,
  woff2 = true,
  ttf = true,
  ico = true,
  jar = true,
  class = true,
}

local MAX_SIZE = 5 * 1024 * 1024

function M._fast_path_ext(path)
  local lower = path:lower()
  -- check last suffix then all compound suffixes
  for ext in lower:gmatch('%.([^.]+)') do
    if BINARY_EXTS[ext] then
      return true
    end
  end
  return false
end

function M._build_mime_probe_cmd(host, rpath)
  return { 'ssh', host, 'file -b --mime-encoding ' .. rpath }
end

function M._build_size_probe_cmd(host, rpath)
  return { 'ssh', host, 'stat -c %s ' .. rpath .. ' 2>/dev/null || wc -c < ' .. rpath }
end

function M._is_binary_mime(out)
  return out:gsub('%s+$', '') == 'binary'
end

local function check_remote_binary(host, rpath)
  local mime = vim.system(M._build_mime_probe_cmd(host, rpath), { text = true }):wait()
  if mime.code == 0 and M._is_binary_mime(mime.stdout or '') then
    return true, 'binary'
  end
  local sz = vim.system(M._build_size_probe_cmd(host, rpath), { text = true }):wait()
  if sz.code == 0 then
    local n = tonumber((sz.stdout or ''):gsub('%s+', '')) or 0
    if n > MAX_SIZE then
      return true, string.format('%dMB > 5MB cap', math.floor(n / 1024 / 1024))
    end
  end
  return false
end

function M.open(host, rpath)
  -- Fast-path extension check (advisory, no SSH)
  if M._fast_path_ext(rpath) and not vim.b.force_binary then
    vim.notify(
      string.format(
        'Binary extension detected for %s. Use :!scp host:path /tmp/ or <leader>sO to force.',
        rpath
      ),
      vim.log.levels.WARN
    )
    return
  end
  -- Authoritative probe
  if not vim.b.force_binary then
    local blocked, reason = check_remote_binary(host, rpath)
    if blocked then
      vim.notify(
        string.format(
          '%s: %s. :!scp host:path /tmp/ manually, or <leader>sO to force.',
          rpath,
          reason
        ),
        vim.log.levels.WARN
      )
      return
    end
  end
  vim.cmd(string.format('edit scp://%s/%s', host, rpath))
end

function M.browse()
  local host = vim.fn.input('Host: ')
  if host == '' then
    return
  end
  local path = vim.fn.input('Path: ')
  if path == '' then
    return
  end
  vim.cmd(string.format('edit scp://%s/%s/', host, path))
end

function M.find()
  local host = vim.fn.input('Host: ')
  if host == '' then
    return
  end
  local path = vim.fn.input('Path: ')
  if path == '' then
    return
  end
  local pat = vim.fn.input('Name pattern: ')
  if pat == '' then
    return
  end
  local cmd = { 'ssh', host, string.format("find %s -name '%s' 2>/dev/null", path, pat) }
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 then
    vim.notify('ssh ' .. host .. ' failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
    return
  end
  local results = {}
  for line in (res.stdout or ''):gmatch('[^\n]+') do
    table.insert(results, line)
  end
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = string.format('find %s:%s  %s', host, path, pat),
      finder = finders.new_table({ results = results }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          actions.close(bufnr)
          local sel = action_state.get_selected_entry()
          if not sel then
            return
          end
          M.open(host, sel[1])
        end)
        return true
      end,
    })
    :find()
end

function M.force_binary()
  vim.b.force_binary = 1
  vim.notify('binary guard disabled for this buffer; re-open with :e to retry', vim.log.levels.INFO)
end

function M.setup() end -- keymaps in lua/plugins/remote.lua

return M