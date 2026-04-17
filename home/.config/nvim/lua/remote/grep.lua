-- lua/remote/grep.lua
local M = {}

function M._parse_input(line)
  local out =
    { timeout = 30, size = '10M', hidden = false, all = false, regex = 'ext', nocase = false }
  for tok in line:gmatch('%S+') do
    local k, v = tok:match('^([^=+][^=]*)=(.+)$')
    if k and v then
      if k == 'pattern' then
        out.pattern = v
      elseif k == 'path' then
        out.path = v
      elseif k == 'glob' then
        out.glob = v
      end
    else
      local fk, fv = tok:match('^%+([^=]+)=(.+)$')
      if fk and fv then
        if fk == 'timeout' then
          out.timeout = tonumber(fv) or 30
        elseif fk == 'size' then
          out.size = fv
        elseif fk == 'regex' then
          out.regex = fv
        end
      else
        local flag = tok:match('^%+(.+)$')
        if flag == 'hidden' then
          out.hidden = true
        elseif flag == 'all' then
          out.all = true
          out.hidden = true
        elseif flag == 'nocase' then
          out.nocase = true
        end
      end
    end
  end
  return out
end

function M._build_cmd(host, opts)
  local grep_flag = 'E'
  if opts.regex == 'perl' then
    grep_flag = 'P'
  elseif opts.regex == 'fixed' then
    grep_flag = 'F'
  end
  local case = opts.nocase and 'i' or ''
  local filters = {}
  if not opts.hidden then
    table.insert(filters, "-not -path '*/.*'")
  end
  if not opts.all then
    table.insert(filters, "-not -path '*/node_modules/*'")
    table.insert(filters, "-not -path '*/venv/*'")
  end
  local size_part = ''
  if opts.size ~= '0' then
    size_part = '-size -' .. opts.size
  end

  local remote = string.format(
    "nice -n19 ionice -c3 timeout %d find %s -type f %s %s -name '%s' -exec grep -%s%sIlH '%s' {} + 2>/dev/null",
    opts.timeout,
    opts.path,
    size_part,
    table.concat(filters, ' '),
    opts.glob,
    grep_flag,
    case,
    opts.pattern
  )
  return { 'ssh', host, remote }
end

function M.prompt()
  local host = vim.fn.input('Host: ')
  if host == '' then
    return
  end
  local line = vim.fn.input(
    'grep [pattern=X path=Y glob=Z +timeout=N +size=NM +regex=ext|perl|fixed +hidden +all +nocase]: '
  )
  if line == '' then
    return
  end
  local opts = M._parse_input(line)
  if not opts.pattern or not opts.path or not opts.glob then
    vim.notify('pattern, path, glob are required', vim.log.levels.ERROR)
    return
  end
  local cmd = M._build_cmd(host, opts)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code == 124 then
    vim.notify('grep timed out. Narrow path/glob or pass +timeout=60', vim.log.levels.WARN)
    return
  end
  local results = {}
  for line_out in (res.stdout or ''):gmatch('[^\n]+') do
    table.insert(results, line_out)
  end
  if #results == 0 then
    vim.notify('no matches', vim.log.levels.INFO)
    return
  end
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = string.format('%s:%s  %s', host, opts.path, opts.pattern),
      finder = finders.new_table({ results = results }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          actions.close(bufnr)
          local sel = action_state.get_selected_entry()
          if not sel then
            return
          end
          require('remote.browse').open(host, sel[1])
        end)
        return true
      end,
    })
    :find()
end

function M.setup() end -- keymaps in lua/plugins/remote.lua

return M