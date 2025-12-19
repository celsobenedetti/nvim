require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.core' },
    { import = 'modules.git' },
    { import = 'modules.editor' },
    { import = 'modules.overseer' },
    { import = 'modules.dap' },
    { import = 'modules.ai' },
    { import = 'modules.ui' },
    { import = 'modules.zk' },
    { import = 'modules.omarchy' },
    { import = 'modules.tmux' },
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
    rtp = { -- disable some rtp plugins
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
})
