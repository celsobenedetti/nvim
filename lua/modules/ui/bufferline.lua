return {
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    enabled = false,
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup()
    end,
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Bufferline: Toggle Pin' },
      { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Bufferline: Delete Non-Pinned Buffers' },
      { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Bufferline: Delete Buffers to the Right' },
      { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Bufferline: Delete Buffers to the Left' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Bufferline: Prev Buffer' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Bufferline: Next Buffer' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Bufferline: Prev Buffer' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Bufferline: Next Buffer' },
      { '[B', '<cmd>BufferLineMovePrev<cr>', desc = 'Bufferline: Move buffer prev' },
      { ']B', '<cmd>BufferLineMoveNext<cr>', desc = 'Bufferline: Move buffer next' },
    },
  },
}
