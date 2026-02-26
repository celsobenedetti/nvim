return {
  {
    'b0o/incline.nvim',
    enabled = vim.g.incline,
    dependencies = { { 'nvim-mini/mini.icons', config = true } },
    config = require('config.plugin.incline').config,
    event = 'VeryLazy',
  },
}
