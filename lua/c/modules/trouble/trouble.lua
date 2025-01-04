return {
  {
    'folke/trouble.nvim',
    lazy = true,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('trouble').setup()
      require 'c.modules.trouble.autocmds.delete_entry'
    end,

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
