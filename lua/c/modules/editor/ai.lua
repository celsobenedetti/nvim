return {
  -- {
  --   'zbirenbaum/copilot.lua',
  --   enabled = vim.g.copilot,
  --   event = 'VeryLazy',
  --   opts = {
  --     filetypes = {
  --       yaml = true,
  --       json = true,
  --     },
  --     suggestion = { enabled = false },
  --     panel = { enabled = false },
  --   },
  -- },
  --
  -- {
  --   'zbirenbaum/copilot-cmp',
  --   enabled = vim.g.copilot,
  --   dependencies = { 'zbirenbaum/copilot.lua' },
  --   config = function()
  --     require('copilot_cmp').setup()
  --   end,
  -- },

  {
    'robitx/gp.nvim',
    cmd = {
      'GpChatNew',
    },
    keys = {
      {
        '<leader>G',
        ':GpChatNew tabnew<CR>',
        desc = 'Open ChatGPT in new tab',
      },
    },
    config = function()
      require('gp').setup()
    end,
  },

  {
    'piersolenski/wtf.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    opts = {},
    keys = {
      {
        'gw',
        mode = { 'n', 'x' },
        function()
          require('wtf').ai()
        end,
        desc = 'Debug diagnostic with AI',
      },
      {
        mode = { 'n' },
        'gW',
        function()
          require('wtf').search()
        end,
        desc = 'Search diagnostic with Google',
      },
    },
  },
}
