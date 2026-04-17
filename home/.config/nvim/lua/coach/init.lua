-- lua/coach/init.lua -- Surface tips for Neovim
local M = {}

local tips = require('coach.tips')
local last_idx = nil

function M.random_tip()
    if #tips == 0 then
        return nil
    end

    return tips[math.random(#tips)]
end

function M.next_tip()
    if #tips == 0 then
        return nil
    end

    if #tips == 1 then
        last_idx = 1
        return tips[1]
    end

    local idx = math.random(#tips)
    while idx == last_idx do
        idx = math.random(#tips)
    end

    last_idx = idx
    return tips[idx]
end

function M.open_cheatsheet()
    local ok, pickers = pcall(require, 'telescope.pickers')
    if not ok then
        vim.notify('telescope not available', vim.log.levels.ERROR)
        return
    end

    local finders = require('telescope.finders')
    local conf = require('telescope.config').values

    pickers
        .new({}, {
            prompt_title = 'coach cheatsheet',
            finder = finders.new_table({
                results = tips,
                entry_maker = function(t)
                    return {
                        value = t,
                        display = string.format('%-20s  %-18s  %s', t.keys, '[' .. t.category .. ']', t.desc),
                        ordinal = t.keys .. ' ' .. t.category .. ' ' .. t.desc,
                    }
                end,
            }),
            sorter = conf.generic_sorter({}),
        })
        :find()
end

function M.setup()
    vim.keymap.set('n', '<leader>?', M.open_cheatsheet, { desc = 'open cheatsheet' })
    vim.keymap.set('n', '<leader>??', function()
      local t = M.next_tip()
      if t then
        vim.notify(string.format('%s — %s (%s)', t.keys, t.desc, t.category))
      end
    end, { desc = 'next tip' })
  end
  
  return M