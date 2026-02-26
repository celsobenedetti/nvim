vim.g.lazy_orgmode = false

require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.base' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
    {
      'b0o/incline.nvim',
      dependencies = { { 'nvim-mini/mini.icons', config = true } },
      config = require('config.plugin.incline').config,
      event = 'VeryLazy',
    },
  },
  performance = vim.g.lazy_nvim_config.performance,
})

local initial_window = vim.api.nvim_get_current_win()
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    pcall(vim.api.nvim_win_close, initial_window, true)
  end,
})
Org.capture.c()
