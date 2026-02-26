local initial_window = vim.api.nvim_get_current_win()

vim.g.lazy_orgmode = false

require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.base' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
    -- BUG: nvim orgmode C-c
    {
      'b0o/incline.nvim',
      dependencies = { { 'nvim-mini/mini.icons', config = true } },
      config = require('config.plugin.incline').config,
    },
  },
  performance = vim.g.lazy_nvim_config.performance,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'close initial window when capture buffer shows',
  pattern = 'org',
  callback = function()
    pcall(vim.api.nvim_win_close, initial_window, true)
    vim.b.capture_buffer = vim.api.nvim_get_current_buf()
  end,
})

Org.capture.c()

vim.opt.number = false
vim.opt.laststatus = 0

vim.api.nvim_set_hl(0, 'Title', { link = 'Special' })
