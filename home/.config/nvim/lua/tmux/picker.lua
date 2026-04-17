-- lua/tmux/picker.lua -- telescope picker listing all cc-* Claude sessions.
-- <leader>cl opens this; Enter attaches via display-popup; <C-x> kills in-place.
local M = {}

local function rel_age(ts)
  if not ts or ts == 0 then
    return '?'
  end
  local secs = os.time() - ts
  if secs < 60 then
    return secs .. 's ago'
  elseif secs < 3600 then
    return math.floor(secs / 60) .. 'm ago'
  elseif secs < 86400 then
    return math.floor(secs / 3600) .. 'h ago'
  end
  return math.floor(secs / 86400) .. 'd ago'
end

local function read_idle(session_name)
  local res = vim
    .system({
      'tmux',
      'show-option',
      '-t',
      session_name,
      '-v',
      '-q',
      '@claude_idle',
    }, { text = true })
    :wait()
  if res.code ~= 0 then
    return nil
  end
  local val = (res.stdout or ''):gsub('%s+$', '')
  if val == '1' then
    return 'idle'
  end
  if val == '0' then
    return 'busy'
  end
  return nil
end

function M.open()
  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then
    vim.notify('telescope.nvim not available', vim.log.levels.ERROR)
    return
  end
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local conf = require('telescope.config').values

  local sessions = require('tmux.sessions').list()
  if #sessions == 0 then
    vim.notify('no Claude sessions open (press <leader>cp to start one)', vim.log.levels.INFO)
    return
  end
  -- Newest first
  table.sort(sessions, function(a, b)
    return (a.created_ts or 0) > (b.created_ts or 0)
  end)

  pickers
    .new({}, {
      prompt_title = 'Claude sessions',
      finder = finders.new_table({
        results = sessions,
        entry_maker = function(s)
          local state = read_idle(s.name)
          local icon = (state == 'idle' and '✓') or (state == 'busy' and '⟳') or '?'
          return {
            value = s,
            display = string.format('%s %-28s  (%s)', icon, s.slug, rel_age(s.created_ts)),
            ordinal = s.slug,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          if not entry then
            return
          end
          vim
            .system({
              'tmux',
              'display-popup',
              '-E',
              '-w',
              '85%',
              '-h',
              '85%',
              'tmux attach -t ' .. entry.value.name,
            })
            :wait()
        end)
        map({ 'i', 'n' }, '<C-x>', function()
          local entry = action_state.get_selected_entry()
          if not entry then
            return
          end
          require('tmux.claude_popup').kill(entry.value.name)
          -- Refresh the picker by closing + reopening
          actions.close(bufnr)
          vim.schedule(M.open)
        end)
        return true
      end,
    })
    :find()
end

return M