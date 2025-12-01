local ok, neotree = pcall(require, 'neo-tree')
if not ok then
  return
end

vim.g.neo_tree_remove_legacy_commands = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

neotree.setup({
  close_if_last_window = true,
  popup_border_style = 'rounded',
  enable_git_status = true,
  enable_diagnostics = true,
  default_component_configs = {
    indent = {
      with_markers = true,
      highlight = 'NeoTreeIndentMarker',
    },
    modified = {
      symbol = '●',
      highlight = 'NeoTreeModified',
    },
    git_status = {
      symbols = {
        added = '',
        modified = '',
        deleted = '',
        renamed = '',
        untracked = '',
        ignored = '',
        unstaged = '󰄱',
        staged = '',
        conflict = '',
      },
    },
  },
  sources = {
    'filesystem',
    'buffers',
    'git_status',
  },
  filesystem = {
    bind_to_cwd = true,
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    hijack_netrw_behavior = 'open_default',
    use_libuv_file_watcher = true,
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
      never_show = { '.git' },
    },
  },
  buffers = {
    follow_current_file = {
      enabled = true,
    },
  },
  window = {
    width = 35,
    mappings = {
      ['<space>'] = 'none',
    },
  },
})
