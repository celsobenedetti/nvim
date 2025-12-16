require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.overseer' },
    { import = 'modules.tmux' },
    { import = 'modules.omarchy' },
    {
      'folke/snacks.nvim',
      opts = {
        picker = {},
      },
    },
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
})
