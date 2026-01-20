vim.g.lazy_orgmode = false

require('init')

require('lazy').setup({
  spec = {
    { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } }, -- no clue why this is needed tbh
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { 'folke/snacks.nvim', opts = { picker = {} } },
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

local DELAY_CLOSE_WIN = 20
Org.capture.c()
vim.schedule(function()
  vim.defer_fn(function()
    vim.cmd('wincmd k')
    vim.api.nvim_win_close(0, false)
  end, DELAY_CLOSE_WIN)
end)
