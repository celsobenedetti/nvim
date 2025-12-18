local tool = 'opencode'

return {
  {

    'folke/sidekick.nvim',
    opts = function()
      local opts = {}
      opts.nes = vim.tbl_deep_extend('force', opts.nes or {}, {
        enabled = false,
      })
    end,
    -- stylua: ignore start
    keys = {
      { '<leader>aa', function() require('sidekick.cli').toggle { name = tool } end, desc = 'Sidekick Toggle', mode = { 'n', 'x' }, },
      { '<leader>af', function() require('sidekick.cli').send { msg = '{file}', name = tool } end, desc = 'Send File', },
      { '<leader>at', function() require('sidekick.cli').send { msg = '{this}', name = tool } end, mode = { 'n' }, desc = 'Send This', },
      { '<leader>at', function() require('sidekick.cli').send { msg = '{selection}', name = tool } end, mode = { 'x' }, desc = 'Send Visual Selection', },
      { '<leader>ad', function() require('sidekick.cli').close() end, desc = 'Detach a CLI Session', },
      { '<leader>ap', function() require('sidekick.cli').prompt { name = tool } end, mode = { 'n', 'x' }, desc = 'Sidekick Select Prompt', },
    -- stylua: ignore end
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
