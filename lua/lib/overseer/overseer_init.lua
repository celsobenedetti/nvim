vim.g.mapleader = ' '
vim.g.performance = true
vim.o.background = 'dark'
require 'config.lazy'
require 'config.globals'

local themes = require 'plugins.theme'
local colorscheme_plugin = themes[1]
local colorscheme = themes[2].opts.colorscheme

require('lazy').setup {
  spec = {
    colorscheme_plugin,
    { import = 'modules.overseer' },
    { import = 'modules.tmux' },
    {
      'folke/snacks.nvim',
      opts = {
        picker = {},
      },
    },
  },
  checker = {
    enabled = false, -- check for plugin updates periodically
    notify = false, -- notify on update
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}

vim.cmd.colorscheme(colorscheme)

require 'config.sensible'
require 'lib.modules.transparency'
