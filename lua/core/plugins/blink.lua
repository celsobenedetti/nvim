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

  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source

    dependencies = {
      'rafamadriz/friendly-snippets',
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      { 'Kaiser-Yang/blink-cmp-dictionary', dependencies = { 'nvim-lua/plenary.nvim' } },
    },

    -- use a release tag to download pre-built binaries
    version = '1.*',
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    config = function()
      local luasnip = require 'luasnip'

      map('i', '<C-l>', function()
        if luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
          return
        end
      end)

      map({ 'i', 's' }, '<C-h>', function()
        if luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        end
      end)

      local disable_on_filetypes = {
        'DressingInput',
        'minifiles',
      }

      local opts = {
        enabled = function()
          return not vim.tbl_contains(disable_on_filetypes, vim.bo.filetype)
        end,
        -- signature = { enabled = true, window = { border = 'single' } },
        signature = {
          enabled = true,
          trigger = {
            enabled = true,
            show_on_trigger_character = true,
            show_on_insert_on_trigger_character = true,
          },
        },

        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- 'super-tab' for mappings similar to vscode (tab to accept)
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- All presets have the following mappings:
        -- C-e: Hide menu
        -- C-k: Toggle signature help (if signature.enabled = true)
        keymap = {
          preset = 'enter',
          ['<C-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
          -- ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
          -- ['<C-e>'] = { 'hide', 'fallback' },
          -- ['<CR>'] = { 'accept', 'fallback' },
          --
          ['<Tab>'] = {},
          ['<S-Tab>'] = {},
          --
          -- ['<Up>'] = { 'select_prev', 'fallback' },
          -- ['<Down>'] = { 'select_next', 'fallback' },
          -- ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
          -- ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
          --
          -- ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
          -- ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
        },

        appearance = {
          -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          -- Adjusts spacing to ensure icons are aligned
          nerd_font_variant = 'mono',
        },

        -- (Default) Only show the documentation popup when manually triggered
        snippets = { preset = 'luasnip' },
        completion = {
          keyword = { range = 'full' },
          menu = {
            border = 'single',
            auto_show = true,
            draw = {
              columns = {
                { 'label', 'label_description', gap = 1 },
                { 'kind_icon', 'kind', gap = 1 },
              },
            },
          },
          documentation = { auto_show = true, window = { border = 'single' } },
        },
        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer', 'dictionary' },
          providers = {
            dictionary = {
              module = 'blink-cmp-dictionary',
              name = 'Dict',
              min_keyword_length = 3,
              opts = {
                dictionary_files = function()
                  if vim.bo.filetype ~= 'markdown' and vim.bo.filetype ~= 'org' then
                    return nil
                  end
                  return { vim.fn.expand '~/.dotfiles/english.dict' }
                end,
              },
            },
          },
        },
      }

      require('blink.cmp').setup(opts)
    end,

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
}
