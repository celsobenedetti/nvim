local spec = {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
  },

  {
    'folke/styler.nvim',
    ft = { 'help' },
    config = function()
      require('styler').setup {
        themes = {
          help = { colorscheme = 'catppuccin-mocha' },
          markdown = { colorscheme = 'catppuccin-mocha' },
        },
      }
    end,
  },

  -- filenamees
  {
    'b0o/incline.nvim',
    opts = function(_, opts)
      opts.window = { margin = { vertical = 0, horizontal = 1 } }
      opts.hide = { cursorline = true }

      opts.render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ':t')
        if vim.bo[props.buf].modified then
          filename = '[+] ' .. filename
        end

        local icon, color = require('nvim-web-devicons').get_icon_color(filename)
        return { { icon, guifg = color }, { ' ' }, { filename } }
      end
    end,
  },
}

return spec
