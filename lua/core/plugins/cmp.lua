return {
  {
    'L3MON4D3/LuaSnip',

    build = 'make install_jsregexp',
    dependencies = {
      {
        'rafamadriz/friendly-snippets',
      },
    },
    config = function()
      -- require('luasnip.loaders.from_vscode').lazy_load {}
      require('luasnip.loaders.from_vscode').lazy_load {
        paths = {
          '/home/celso/.config/nvim',
          '/home/celso/.local/share/nvim/lazy/friendly-snippets',
        },
      }
    end,
  },
  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    opts = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        --- appearance
        window = {
          completion = cmp.config.window.bordered {},
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          format = function(_, vim_item)
            vim_item.kind = (C.ui.icons.kinds[vim_item.kind] or '') .. vim_item.kind
            return vim_item
          end,
        },

        completion = { completeopt = 'menu,menuone,noinsert' },

        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- FIX: something is off here where sometimges these mappings select the item
          ['<C-n>'] = cmp.mapping.select_next_item { select = false, accept = false }, -- Select the [n]ext item
          ['<C-j>'] = cmp.mapping.select_next_item { select = false, accept = false }, -- Select the [n]ext item
          ['<C-k>'] = cmp.mapping.select_prev_item { select = false, accept = false }, -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item { select = false, accept = false }, -- Select the [p]revious item

          ['<C-y>'] = cmp.mapping.confirm { select = true },
          ['<CR>'] = cmp.mapping.confirm { select = true },

          -- ['<Tab>'] = false,
          -- ['<S-Tab>'] = false,
          -- ['<Tab>'] = cmp.mapping.confirm { select = true },

          ['<C-Space>'] = cmp.mapping.complete {},

          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'copilot' },
          -- { name = 'supermaven' },
          { name = 'dictionary', keyword_length = 2 },
          { name = 'orgmode' },
        },
      }
      map('i', '<C-Space>', cmp.mapping.complete, { desc = 'cmp: Trigger Completion' })

      cmp.setup.buffer { enabled = C.opt.completion }
    end,
  },
}
