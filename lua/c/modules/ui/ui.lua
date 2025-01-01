return {
  -- TODO: change this for snack zen
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
  }, ft = { 'toml' } },
}
