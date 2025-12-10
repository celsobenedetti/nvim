return {
  {
    'bassamsdata/namu.nvim',
    lazy = true,
    keys = {
      { '<leader>ns', '<cmd>Namu symbols<cr>', desc = 'Namu: document symbols' },
      { '<leader>ds', '<cmd>Namu symbols<cr>', desc = 'Namu: document symbols' },
      { '<leader>nw', '<cmd>Namu workspace<cr>', desc = 'Namu: workspace symbols' },
      { '<leader>ws', '<cmd>Namu workspace<cr>', desc = 'Namu: workspace symbols' },
    },
    config = function()
      require('namu').setup {}
    end,
  },
}
