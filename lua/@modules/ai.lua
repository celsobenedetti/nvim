return {
  {
    'zbirenbaum/copilot.lua',
    event = 'VeryLazy',
    opts = {
      filetypes = {
        yaml = true,
        json = true,
      },
      suggestion = {
        auto_trigger = false,
      },
    },
  },

  {
    'zbirenbaum/copilot-cmp',
    config = function()
      require('copilot_cmp').setup()
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
