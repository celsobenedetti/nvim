return {
  {
    'saghen/blink.pairs',
    version = '*', -- (recommended) only required with prebuilt binaries

    -- download prebuilt binaries from github releases
    dependencies = 'saghen/blink.download',
    -- OR build from source, requires nightly:
    -- https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        -- you can call require("blink.pairs.mappings").enable()
        -- and require("blink.pairs.mappings").disable()
        -- to enable/disable mappings at runtime
        enabled = true,
        cmdline = true,
        -- or disable with `vim.g.pairs = false` (global) and `vim.b.pairs = false` (per-buffer)
        -- and/or with `vim.g.blink_pairs = false` and `vim.b.blink_pairs = false`
        disabled_filetypes = {},
        -- see the defaults:
        -- https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua
        -- pairs = {},
        pairs = {
          ['!'] = { { '<!--', '-->', languages = { 'html', 'markdown', 'markdown_inline' } } },
          ['('] = ')',
          ['['] = {
            {
              '[',
              ']',
              space = function()
                return vim.bo.filetype ~= 'markdown' and vim.bo.filetype ~= 'org'
              end,
            },
          },
          ['{'] = '}',
          ["'"] = {
            {
              "'''",
              when = function(ctx)
                return ctx:text_before_cursor(2) == "''"
              end,
              languages = { 'python' },
            },
            {
              "'",
              enter = false,
              space = false,
              when = function(ctx)
                -- The `plaintex` filetype has no treesitter parser, so we can't disable
                -- this pair in math environments. Thus, disable this pair completely.
                -- TODO: disable inside "" strings?
                return ctx.ft ~= 'plaintext'
                  and ctx.ft ~= 'scheme'
                  and (not ctx.char_under_cursor:match('%w') or ctx:is_after_cursor("'"))
                  and ctx.ts:blacklist('singlequote').matches
              end,
            },
          },
          ['"'] = {
            {
              'r#"',
              '"#',
              languages = { 'rust' },
              priority = 100,
            },
            {
              '"""',
              when = function(ctx)
                return ctx:text_before_cursor(2) == '""'
              end,
              languages = { 'python', 'elixir', 'julia', 'kotlin', 'scala' },
            },
            { '"', enter = false, space = false },
          },
          ['`'] = {
            {
              '```',
              when = function(ctx)
                return ctx:text_before_cursor(2) == '``'
              end,
              languages = { 'markdown', 'markdown_inline', 'typst', 'vimwiki', 'rmarkdown', 'rmd', 'quarto' },
            },
            {
              '`',
              "'",
              languages = { 'bibtex', 'latex', 'plaintex' },
            },
            { '`', enter = false, space = false },
          },
          ['_'] = {
            {
              '_',
              when = function(ctx)
                return not ctx.char_under_cursor:match('%w') and ctx.ts:blacklist('underscore').matches
              end,
              languages = { 'typst' },
            },
          },
          ['*'] = {
            {
              '*',
              when = function(ctx)
                return ctx.ts:blacklist('asterisk').matches
              end,
              languages = { 'typst' },
            },
          },
          ['<'] = {
            {
              '<',
              '>',
              when = function(ctx)
                return ctx.ts:whitelist('angle').matches
              end,
              languages = { 'rust' },
            },
          },
          ['$'] = {
            {
              '$',
              languages = { 'markdown', 'markdown_inline', 'typst', 'latex', 'plaintex' },
            },
          },
        },
      },
      highlights = {
        enabled = true,
        -- requires require('vim._extui').enable({}), otherwise has no effect
        cmdline = true,
        -- groups = {
        --   'BlinkPairsOrange',
        --   'BlinkPairsPurple',
        --   'BlinkPairsBlue',
        -- },
        unmatched_group = 'BlinkPairsUnmatched',

        -- highlights matching pairs under the cursor
        matchparen = {
          enabled = true,
          -- known issue where typing won't update matchparen highlight, disabled by default
          cmdline = false,
          -- also include pairs not on top of the cursor, but surrounding the cursor
          include_surrounding = false,
          group = 'BlinkPairsMatchParen',
          priority = 250,
        },
      },
      debug = false,
    },
  },
}
