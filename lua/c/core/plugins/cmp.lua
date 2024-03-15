return {
  {
    'L3MON4D3/LuaSnip',
    build = 'make install_jsregexp',
    dependencies = {
      {
        'rafamadriz/friendly-snippets',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load {}
        end,
      },
    },
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
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        -- window = {
        --   completion = cmp.config.window.bordered {},
        --   documentation = cmp.config.window.bordered(),
        -- },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(), -- Select the [n]ext item
          ['<C-j>'] = cmp.mapping.select_next_item(), -- Select the [n]ext item
          ['<C-p>'] = cmp.mapping.select_prev_item(), -- Select the [p]revious item
          ['<C-k>'] = cmp.mapping.select_prev_item(), -- Select the [p]revious item

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },
          ['<CR>'] = cmp.mapping.confirm { select = true },
          ['<Tab>'] = cmp.mapping.confirm { select = true },

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
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
        },
      }
    end,
  },

  {
    'uga-rosa/cmp-dictionary',
    -- TODO: see if newer versions work
    commit = 'd17bc1f87736b6a7f058b2f246e651d34d648b47',
    config = function()
      local dict = require 'cmp_dictionary'
      dict.setup {
        -- The following are default values.
        exact = 2,
        first_case_insensitive = false,
        document = false,
        document_command = 'wn %s -over',
        async = false,
        sqlite = false,
        max_items = -1,
        capacity = 5,
        debug = false,
      }
      -- dict.update()
      dict.switcher {
        spelllang = {
          en = '~/.dotfiles/english.dict',
        },
      }
    end,
    ft = { 'markdown', 'tex', 'latex', 'vimwiki', 'gitcommit' },
    dependencies = {
      {
        'hrsh7th/nvim-cmp',
        opts = function(_, opts)
          local cmp = require 'cmp'
          opts.sources = cmp.config.sources(vim.list_extend(opts.sources or {}, {
            { name = 'dictionary', keyword_length = 2 },
          }))
        end,
      },
    },
  },
}
