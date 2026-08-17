return {
  -- lazy.nvim
  {
    'antonk52/markdowny.nvim',
    ft = { 'markdown' },
    config = function()
      require('markdowny').setup()
    end,
  },
}
