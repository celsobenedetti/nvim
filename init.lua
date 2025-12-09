require 'config.lazy'
require 'config.globals'
require 'config.options'
require 'config.sensible'
require 'config.autocmds'
require 'config.keymaps'

require('lazy').setup {

  spec = {
    { 'wakatime/vim-wakatime' }, -- code time tracking goodness
    { import = 'modules.core' },
    { import = 'modules.tmux' },
    { import = 'modules.editor' },
    { import = 'modules.omarchy' },
    { import = 'modules.ui' },
    { import = 'modules.git' },
    { import = 'modules.overseer' },

    -- lazyload
    -- { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } },

    -- { import = 'lib.plugins.performance' },
    -- { import = 'lib.plugins.disable' },
  },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
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

require 'config.transparency'
