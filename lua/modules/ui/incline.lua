return {
  {
    'b0o/incline.nvim',
    enabled = vim.g.incline,
    dependencies = { 'nvim-mini/mini.icons' },
    config = function()
      require('incline').setup {}
    end,
    event = 'VeryLazy',
  },
}
