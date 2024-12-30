return {

  -- { 'catppuccin/nvim' },
  { 'ellisonleao/gruvbox.nvim', priority = 1000, config = true, lazy = true },
  { 'rose-pine/neovim', name = 'rose-pine', opts = {
    styles = { italic = false },
  } },
  -- { 'nyoom-engineering/oxocarbon.nvim' },
  -- {
  --   'projekt0n/github-nvim-theme',
  --   lazy = false, -- make sure we load this during startup if it is your main colorscheme
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require('github-theme').setup {}
  --   end,
  -- },

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

  { 'norcalli/nvim-colorizer.lua', config = {
    'toml',
  } },
}
