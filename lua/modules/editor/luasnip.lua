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

  -- add snippet_forward action
  -- {
  --   'L3MON4D3/LuaSnip',
  --   opts = function()
  --     LazyVim.cmp.actions.snippet_forward = function()
  --       if require('luasnip').jumpable(1) then
  --         vim.schedule(function()
  --           require('luasnip').jump(1)
  --         end)
  --         return true
  --       end
  --     end
  --     LazyVim.cmp.actions.snippet_stop = function()
  --       if require('luasnip').expand_or_jumpable() then -- or just jumpable(1) is fine?
  --         require('luasnip').unlink_current()
  --         return true
  --       end
  --     end
  --   end,
  -- },
}
