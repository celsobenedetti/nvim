return {
  {
    'olimorris/codecompanion.nvim',
    keys = {
      { '<leader>ca', '<cmd>CodeCompanionActions<cr>', desc = 'CodeCompanion actions', mode = { 'n', 'v' } },
      { '<leader>cc', '<cmd>CodeCompanionChat<cr>', desc = 'CodeCompanion chat', mode = { 'n', 'v' } },
    },
    config = function()
      require('codecompanion').setup {
        adapters = {
          openai = function()
            return require('codecompanion.adapters').extend('openai', {
              schema = {
                model = {
                  default = 'gpt-4.1',
                },
              },
            })
          end,
        },
        strategies = {
          chat = {
            adapter = 'openai',
          },
          inline = {
            adapter = 'openai',
          },
          cmd = {
            adapter = 'openai',
          },
        },
      }
    end,

    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
