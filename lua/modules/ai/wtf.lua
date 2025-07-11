return {
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
          require('wtf').diagnose()
        end,
        desc = 'Debug diagnostic with GPT',
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
