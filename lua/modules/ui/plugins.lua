return {
  {
    import = 'lib.plugins.winbar.setup',
    dependencies = {
      'SmiteshP/nvim-navic',
      'nvim-web-devicons',
    },
    enabled = C.opt.winbar and not C.opt.performance,
  },

  { 'levouh/tint.nvim', opts = true, lazy = C.opt.performance }, -- Slightly tint unfocused pane
  {
    'folke/twilight.nvim',
    lazy = true,
    config = function()
      require('twilight').setup {
        -- context = 20, -- amount of lines we will try to show around the current line
      }
    end,
    ft = { 'markdown' },
    keys = { { '<leader>tw', ':Twilight<CR>' } },
  },

  {
    -- HEX/RGB Colorizer plugin
    'echasnovski/mini.hipatterns',
    lazy = C.opt.performance,
    ft = {
      'toml',
      'lua',
    },
    config = function()
      local hipatterns = require 'mini.hipatterns'
      hipatterns.setup {
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          -- fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          -- hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          -- todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          -- note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      }
    end,
  },
}
