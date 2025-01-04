return {

  {
    'nvim-neotest/neotest',
    lazy = true,
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
              if cwd:find 'chatbot' then
                if path:find 'packages/conversation' then
                  return cwd .. '/packages/conversation'
                end

                if path:find 'nestjs' then
                  if cwd:find 'nestjs' then
                    return cwd
                  end
                  return cwd .. '/nestjs'
                end
              end
              return cwd
            end,
          },
        },
      }
    end,
  },
}
