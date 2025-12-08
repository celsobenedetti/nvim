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
}
