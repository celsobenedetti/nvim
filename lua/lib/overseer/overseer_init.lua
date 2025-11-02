vim.g.mapleader = ' '
vim.g.performance = true
vim.o.background = 'dark'
require 'config.lazy'
require 'config.globals'

local omarchy_colorscheme = require('lib.colors').omarchy_colorscheme()
local colorscheme = omarchy_colorscheme.colorscheme
local colorscheme_plugin = omarchy_colorscheme.colorscheme_plugin

print(vim.inspect { omarchy_colorscheme })

require('lazy').setup {
  spec = {
    { colorscheme_plugin },
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
