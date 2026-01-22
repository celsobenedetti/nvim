vim.g.lazy_orgmode = false

local mini = require('modules.core.mini')
require('init')

require('lazy').setup({
  spec = {
    mini,
    { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } }, -- no clue why this is needed tbh
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
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
