local function get_cwd()
  local path = vim.fn.expand '%:p' --[[@as string]]
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
end

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
        '<leader>te',
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
        desc = 'Neotest debug test',
      },
      { '<leader>ts', ':Neotest summary<CR>', desc = 'Neotest summary' },
    },
    cmd = { 'Neotest' },
    config = function()
      require('neotest').setup {
        discovery = {
          enabled = false,
        },
        adapters = {
          require 'neotest-jest' {
            jestCommand = 'pnpm test --',
            jestConfigFile = function()
              local cwd = get_cwd()
              return cwd .. '/jest.config.js'
            end,
            env = { CI = true },
            cwd = function(_)
              return get_cwd()
            end,
            -- is_test_file = function(path)
            --   return path:find 'spec.ts' or path:find 'test.ts'
            -- end,
          },
        },
      }
    end,
  },
}
