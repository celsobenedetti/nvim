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
    keys = {
      -- stylua: ignore start
      { '<C-\\>', function() require('sidekick.cli').toggle { name = tool } end, desc = 'sidekick: Sidekick Toggle', mode = { 'n', 'x', 't' }, },
      { 'gab', function() require('sidekick.cli').send { msg = '{file}', name = tool } end, desc = 'sidekick: Send File', },
      { 'ga.', function() require('sidekick.cli').send { msg = '{line}', name = tool } end, mode = { 'n' }, desc = 'sidekick: Send This', },
      { 'gav', function() require('sidekick.cli').send { msg = '{selection}', name = tool } end, mode = { 'x' }, desc = 'sidekick: Send Visual Selection', },
      { 'gap', function() require('sidekick.cli').prompt { name = tool } end, mode = { 'n', 'x' }, desc = 'sidekick: Sidekick Select Prompt', },
      { '<leader>ad', function() require('sidekick.cli').close() end, desc = 'sidekick: Detach a CLI Session', },

      -- stylua: ignore end

      -- Cursor-like C-k
      {
        '<C-k>',
        function()
          local start, finish = require('lib.visual').get_region()
          vim.ui.input({
            prompt = string.format('%s apply instructions to lines %d-%d: ', tool, start, finish),
          }, function(prompt)
            if not prompt or #prompt == 0 then
              return
            end

            local filepath = vim.fn.expand('%:.')
            local selection = string.format('%s:%d-%d', filepath, start, finish)
            require('sidekick.cli').send({ msg = prompt .. '\n' .. selection, submit = true, name = tool })
          end)
        end,
        mode = { 'x' },
        desc = 'sidekick: apply instructions to selection (Cursor C-k)',
      },

      {
        '<tab>',
        function()
          if not require('sidekick').nes_jump_or_apply() then
            return '<Tab>'
          end
        end,
        expr = true,
        desc = 'Goto/Apply Next Edit Suggestion',
        mode = { 'n' },
      },
    },
  },
  {
    'folke/snacks.nvim',
    optional = true,
    -- opts = {
    --   cli = {
    --     mux = {
    --       enabled = true,
    --       backend = 'tmux',
    --     },
    --   },
    -- },
  },
}
