require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.overseer' },
    { import = 'modules.tmux' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
  },
  performance = vim.g.lazy_nvim_config.performance,
})
