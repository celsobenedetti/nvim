return {

  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-jest',
    },
    keys = {
      {
        '<leader>tf',
        function()
          require('neotest').run.run(vim.fn.expand '%')
        end,
        desc = 'Neotest run file',
      },
      {
        '<leader>tt',
        function()
          require('neotest').run.run()
        end,
        desc = 'Neotest run nearest',
      },
      {
        '<leader>td',
        function()
          require('neotest').run.run { strategy = 'dap' }
        end,
        desc = 'Neotest run nearest',
      },
      { '<leader>ts', ':Neotest summary<CR>', desc = 'Neotest summary' },
    },
    cmd = { 'Neotest' },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-jest' {
            jestCommand = 'pnpm test --',
            jestConfigFile = 'jest.config.js',
            env = { CI = true },
            cwd = function(path)
              local cwd = vim.fn.getcwd()
              print(cwd)
              if cwd:find 'chatbot' then
                return cwd .. '/packages/conversation'
              end
              return cwd
            end,
          },
        },
      }
    end,
  },
}
