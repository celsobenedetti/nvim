return {
  {
    'stevearc/overseer.nvim',
    cmd = {
      'OverseerOpen',
      'OverseerClose',
      'OverseerToggle',
      'OverseerRunCmd',
      'OverseerRun',
      'OverseerInfo',
      'OverseerBuild',
      'OverseerQuickAction',
      'OverseerTaskAction',
      'OverseerClearCache',
    },
    opts = {
      dap = false,

      task_list = {
        -- TODO: wtf are these numbers?
        min_height = { 100, 0.1 },
        bindings = {
          ['<C-h>'] = false,
          ['<C-j>'] = false,
          ['<C-k>'] = false,
          ['<C-l>'] = false,
        },
      },
      form = {
        win_opts = {
          winblend = 0,
        },
      },
      confirm = {
        win_opts = {
          winblend = 0,
        },
      },
      task_win = {
        win_opts = {
          winblend = 0,
        },
      },
    },

    config = function(_, opts)
      local overseer = require 'overseer'
      local edge_server = require 'lib.overseer.edge-server'

      overseer.setup(opts)
      overseer.register_template(edge_server.test)
      overseer.register_template(edge_server.lint)
    end,
    -- stylua: ignore
    keys = {
      { "<leader>OR", "<cmd>OverseerRun<cr>",         desc = "Overseer: Run task" },
      { "<leader>run", "<cmd>OverseerRun<cr>",         desc = "Overseer: Run task" },
      { "<leader>OT", "<cmd>OverseerToggle<cr>",      desc = "Overseer: Toggle" },
      { "<leader>OQ", "<cmd>OverseerQuickAction<cr>", desc = "Overseer: Action recent task" },
      { "<leader>OI", "<cmd>OverseerInfo<cr>",        desc = "Overseer: Overseer Info" },
      { "<leader>OB", "<cmd>OverseerBuild<cr>",       desc = "Overseer: Task builder" },
      { "<leader>OA", "<cmd>OverseerTaskAction<cr>",  desc = "Overseer: Task action" },
      { "<leader>OC", "<cmd>OverseerClearCache<cr>",  desc = "Overseer: Clear cache" },
    },
  },
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      spec = {
        { '<leader>o', group = 'overseer' },
      },
    },
  },
  -- {
  --   'folke/edgy.nvim',
  --   optional = true,
  --   opts = function(_, opts)
  --     opts.right = opts.right or {}
  --     table.insert(opts.right, {
  --       title = 'Overseer',
  --       ft = 'OverseerList',
  --       open = function()
  --         require('overseer').open()
  --       end,
  --     })
  --   end,
  -- },
  {
    'nvim-neotest/neotest',
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.consumers = opts.consumers or {}
      opts.consumers.overseer = require 'neotest.consumers.overseer'
    end,
  },
  {
    'mfussenegger/nvim-dap',
    optional = true,
    opts = function()
      require('overseer').enable_dap()
    end,
  },
}
