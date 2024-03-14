return {
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'folke/trouble.nvim',
    },
    keys = {
      { '<leader>tt', ':TodoTelescope<CR>' },
      { '<leader>tT', ':TodoTrouble<CR>' },
    },
    opts = { signs = false },
  },
}
