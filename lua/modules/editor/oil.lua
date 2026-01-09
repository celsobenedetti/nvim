return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  lazy = false, -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  keys = {
    { '-', ':Oil<cr>', { desc = 'oil: Open parent directory' } },
  },
}
