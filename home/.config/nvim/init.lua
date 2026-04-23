-- init.lua
require("debug_config")
require("profile_config")

local nvim_start_time = vim.uv.hrtime()

vim.loader.enable()

_G.Config = {
  nvim_start_time = nvim_start_time,
  called = {},

  -- treesitter
  use_treesitter_parser = true,
  use_nvim_treesitter = true,
  use_arborist = false,
  use_diffview = false,
  use_codediff = true,
}

function _G.Config.add(spec)
  require("merge")(_G.Config, spec)
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("options")
require("keymaps")