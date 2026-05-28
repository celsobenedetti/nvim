return {
  {
    'b0o/incline.nvim',
    dependencies = { { 'nvim-mini/mini.icons', config = true } },
    config = require('config.plugin.incline').config,
    event = 'VeryLazy',
  },
}
