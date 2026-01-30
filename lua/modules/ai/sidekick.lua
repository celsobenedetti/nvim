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
      { '<C-\\>', function() require('sidekick.cli').toggle { name = tool } end, desc = 'Sidekick Toggle', mode = { 'n', 'x', 't' }, },
      { 'gab', function() require('sidekick.cli').send { msg = '{file}', name = tool } end, desc = 'Send File', },
      { 'ga.', function() require('sidekick.cli').send { msg = '{line}', name = tool } end, mode = { 'n' }, desc = 'Send This', },
      { 'gav', function() require('sidekick.cli').send { msg = '{selection}', name = tool } end, mode = { 'x' }, desc = 'Send Visual Selection', },
      { 'gap', function() require('sidekick.cli').prompt { name = tool } end, mode = { 'n', 'x' }, desc = 'Sidekick Select Prompt', },
      -- { '<leader>at', function() require('sidekick.cli').send { msg = '{this}', name = tool } end, mode = { 'n' }, desc = 'Send This', },
      { '<leader>ad', function() require('sidekick.cli').close() end, desc = 'Detach a CLI Session', },
    -- stylua: ignore end

      { '<C-k>', function() 
        local start, finish = require('lib.visual').get_region()
        Snacks.input.input({prompt="apply instructions to selection"}, function(prompt)
          if not prompt or #prompt == 0 then return end

          local filepath = vim.fn.expand('%:.')
          local selection = string.format("%s:%d-%d", filepath, start, finish)
          require('sidekick.cli').send { msg = prompt .. '\n' .. selection , submit = true , name = tool }
        end)
      end, mode = { 'x' }, desc = 'sidekick: quick edit on visual selection', },
    },
  },
  {
    'folke/snacks.nvim',
    optional = true,
    opts = {
      cli = {
        mux = {
          enabled = true,
          backend = 'tmux',
        },
      },
      -- picker = {
      --   actions = {
      --     sidekick_send = function(...)
      --       return require('sidekick.cli.picker.snacks').send()
      --     end,
      --   },
      --   win = {
      --     input = {
      --       keys = {
      --         ['<a-a>'] = {
      --           'sidekick_send',
      --           mode = { 'n', 'i' },
      --         },
      --       },
      --     },
      --   },
      -- },
    },
  },
}
