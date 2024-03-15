return {
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},

    keys = {
      {
        '<leader>xx',
        function()
          require('trouble').toggle()
        end,
        desc = 'Trouble toggle',
      },
      {
        '<leader>xq',
        function()
          require('trouble').toggle 'quickfix'
        end,
        desc = 'Trouble quickxfix',
      },
      {
        '<leader>xl',
        function()
          require('trouble').toggle 'loclist'
        end,
        desc = 'Trouble loclist',
      },
      {
        'gR',
        function()
          require('trouble').toggle 'lsp_references'
        end,
        desc = 'Trouble lsp references',
      },
    },
  },
}
