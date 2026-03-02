return {
  {
    'hedyhli/outline.nvim',
    keys = {
      { '<leader>out', ':Outline<CR>', desc = 'Toggle Outline' },
    },
    config = function()
      require('outline').setup({})
    end,
  },
}
