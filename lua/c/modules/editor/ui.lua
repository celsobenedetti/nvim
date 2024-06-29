return {

  -- {
  --   'catppuccin/nvim',
  --   name = 'catppuccin',
  --   priority = 1000,
  -- },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    opts = function(_, opts)
      opts.styles = {
        bold = true,
        italic = false,
        transparency = false,
      }
      -- code
    end,
  },

  {
    'folke/styler.nvim',
    ft = { 'help' },
    config = function()
      require('styler').setup {
        themes = {
          help = { colorscheme = vim.g.pretty_colorscheme },
          markdown = { colorscheme = vim.g.pretty_colorscheme },
        },
      }
    end,
  },

  {
    'folke/twilight.nvim',
    config = function()
      require('twilight').setup {
        -- context = 20, -- amount of lines we will try to show around the current line
      }
    end,
    ft = { 'markdown' },
    keys = { { '<leader>tw', ':Twilight<CR>' } },
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

  {
    'levouh/tint.nvim',
    opts = true,
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '│',
        tab_char = '│',
      },
      scope = { enabled = false, show_start = false, show_end = false },
    },
  },
}
