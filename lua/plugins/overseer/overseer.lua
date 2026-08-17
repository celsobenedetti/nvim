return {
  {
    'stevearc/overseer.nvim',
    lazy = true,
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
        -- min_width = {40, 0.1} means "the greater of 40 columns or 10% of total"
        min_height = { 20, 0.2 },
        keymaps = {
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
      local overseer = require('overseer')

      overseer.setup(opts)
      require('config.overseer.edge-server').setup(overseer)
      require('config.overseer.airflow-pipeline').setup(overseer)
    end,
    -- stylua: ignore
    keys = {
      -- { "<leader>OR", "<cmd>OverseerRun<cr>",         desc = "Overseer: Run task" },
      { "<leader>run", "<cmd>OverseerRun<cr>",         desc = "Overseer: Run task" },
      { "♥", "<cmd>OverseerToggle<cr>",      desc = "Overseer: Toggle" }, -- C-S-R set in terminal
      -- { "<C-]>", "<cmd>OverseerToggle<cr>",      desc = "Overseer: Toggle" },
      { "<leader>OQ", "<cmd>OverseerQuickAction<cr>", desc = "Overseer: Action recent task" },
      { "<leader>OI", "<cmd>OverseerInfo<cr>",        desc = "Overseer: Overseer Info" },
      { "<leader>OB", "<cmd>OverseerBuild<cr>",       desc = "Overseer: Task builder" },
      { "<leader>OA", "<cmd>OverseerTaskAction<cr>",  desc = "Overseer: Task action" },
      { "<leader>OC", "<cmd>OverseerClearCache<cr>",  desc = "Overseer: Clear cache" },
    },
  },
}
