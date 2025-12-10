return {
  {
    'L3MON4D3/LuaSnip',
    keys = {
      {
        '<C-l>',
        mode = 'i',
        function()
          local luasnip = require 'luasnip'
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
            return
          end
        end,
      },
      {
        '<C-h>',
        mode = 'i',
        function()
          local luasnip = require 'luasnip'
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end,
      },
    },
  },

  {
    'L3MON4D3/LuaSnip',
    lazy = true,
    dependencies = {
      {
        'rafamadriz/friendly-snippets',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
          require('luasnip.loaders.from_vscode').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snippets' } }
        end,
      },
    },
    opts = {
      history = true,
      delete_check_events = 'TextChanged',
    },
  },
}
