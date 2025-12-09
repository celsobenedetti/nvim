return {
  -- lualine
  {
    'folke/sidekick.nvim',
    opts = function()
      local opts = {}
      opts.nes = vim.tbl_deep_extend('force', opts.nes or {}, {
        enabled = false,
      })
    end,
    keys = {
      {
        '<leader>aa',
        function()
          require('sidekick.cli').toggle { name = 'opencode' }
        end,
        desc = 'Sidekick Toggle',
        mode = { 'n', 'x' },
      },
      {
        '<leader>af',
        function()
          require('sidekick.cli').send { msg = '{file}', name = 'opencode' }
        end,
        desc = 'Send File',
      },
      {
        '<leader>at',
        function()
          require('sidekick.cli').send { msg = '{this}', name = 'opencode' }
        end,
        mode = { 'n' },
        desc = 'Send This',
      },
      {
        '<leader>at',
        function()
          require('sidekick.cli').send { msg = '{selection}', name = 'opencode' }
        end,
        mode = { 'x' },
        desc = 'Send Visual Selection',
      },
      {
        '<leader>ad',
        function()
          require('sidekick.cli').close()
        end,
        desc = 'Detach a CLI Session',
      },
      {
        '<leader>ap',
        function()
          require('sidekick.cli').prompt { name = 'opencode' }
        end,
        mode = { 'n', 'x' },
        desc = 'Sidekick Select Prompt',
      },
    },
  },
  {
    'folke/snacks.nvim',
    optional = true,
    opts = {
      picker = {
        actions = {
          sidekick_send = function(...)
            return require('sidekick.cli.picker.snacks').send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ['<a-a>'] = {
                'sidekick_send',
                mode = { 'n', 'i' },
              },
            },
          },
        },
      },
    },
  },
}
