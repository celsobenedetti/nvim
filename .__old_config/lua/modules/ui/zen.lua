return {

  'folke/snacks.nvim',

  keys = {
    {
      '<leader>uz',
      function()
        Snacks.zen()
      end,
      desc = 'toggle Zen',
    },
  },
  opts = function(_, opts)
    Snacks.config.style('zen', {
      enter = true,
      fixbuf = false,
      minimal = false,
      width = 120,
      height = 0,
      backdrop = { transparent = false, blend = 99 },
      keys = { q = false },
      zindex = 40,

      wo = {
        winhighlight = 'NormalFloat:Normal',
        number = false,
        relativenumber = false,
      },
      w = {
        snacks_main = true,
        lualine = false,
      },
    })

    opts.zen = opts.zen or {}
    opts.zen.on_close = function()
      require('twilight').toggle()
    end
    opts.zen.on_open = function()
      require('twilight').toggle()
    end

    opts.zen.show = {
      statusline = false, -- This hides the statusline (including lualine)
      tabline = false, -- This also hides the tabline
    }

    opts.zen.toggles = {
      dim = false,
      git_signs = false,
      snacks_main = true,
      snacks_indent = true,
      snacks = {
        indent = true,
      },
      -- diagnostics = false,
      -- inlay_hints = false,
    }
  end,
}
