return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = 'VeryLazy',
    keys = {
      { '<c-space>', desc = 'Increment selection' },
      { '<bs>', desc = 'Decrement selection', mode = 'x' },
    },
    opts = {
      ensure_installed = {
        'css',
        'graphql',
        'http',
        'make',
        'markdown',
        'markdown_inline',
        'mermaid',
        'sql',
        'proto',
        'tsx',
        'vue',
        'xml',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer' },
          goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer' },
          goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer' },
          goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer' },
        },
      },
    },

    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  -- Show context of the current function
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    enabled = true,
    opts = { mode = 'cursor', max_lines = 3 },
    keys = {
      {
        '<leader>ut',
        function()
          local tsc = require 'treesitter-context'
          tsc.toggle()
          print 'Toggled Treesitter Context'
        end,
        desc = 'Toggle Treesitter Context',
      },
    },
  },
}
