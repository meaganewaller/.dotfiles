local utils = require('utils')
local base = require('base')

for i = 1, 6 do
  base.add_leader_keymapping(
    string.format('n|%d', i),
    { string.format('%d<C-w><C-w>', i), name = string.format('Select window %d', i) }
  )
end

base.add_leader_keymapping('n|ws', { '<C-w>s', name = 'Split window below' })
base.add_leader_keymapping('n|wv', { '<C-w>v', name = 'Split window right' })
base.add_leader_keymapping('n|w-', { '<C-w>s', name = 'Split window below' })
base.add_leader_keymapping('n|w/', { '<C-w>v', name = 'Split window right' })
base.add_leader_keymapping('n|ww', { '<C-w>w', name = 'Other window' })
base.add_leader_keymapping('n|wj', { '<C-w>j', name = 'Go to the down window' })
base.add_leader_keymapping('n|wk', { '<C-w>k', name = 'Go to the up window' })
base.add_leader_keymapping('n|wh', { '<C-w>h', name = 'Go to the left window' })
base.add_leader_keymapping('n|wl', { '<C-w>l', name = 'Go to the right window' })
base.add_leader_keymapping('n|wd', { '<C-w>c', name = 'Delete window' })
base.add_leader_keymapping('n|wm', { '<C-w>o', name = 'Maximize window' })
