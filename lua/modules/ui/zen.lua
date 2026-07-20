return {

  'folke/snacks.nvim',
  keys = {
    {
      '<leader>uz',
      function()
        Snacks.zen({
          win = {
            style = {
              enter = true,
              fixbuf = false,
              minimal = true,
              width = math.floor(vim.go.columns * 0.7),
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
            },
          },
        })
      end,
      desc = 'toggle Zen',
    },
  },
  opts = function(_, opts)
    --- @type snacks.zen.Config
    opts.zen = {
      on_open = function()
        vim.g.zen_mode = true

        vim.cmd('norm zt')

        vim.api.nvim_set_hl(0, 'Folded', { fg = vim.g.colors.bg, bg = 'none' })
      end,
      on_close = function()
        vim.g.zen_mode = false
        vim.api.nvim_set_hl(0, 'Folded', { link = 'Normal' })
      end,
      show = {
        statusline = false, -- This hides the statusline (including lualine)
        tabline = false, -- This also hides the tabline
      },
      toggles = {
        dim = false,
        git_signs = false,
        snacks_main = true,
        snacks_indent = true,
        snacks = {
          indent = true,
        },
        -- diagnostics = false,
        -- inlay_hints = false,
      },
    }
  end,
}
