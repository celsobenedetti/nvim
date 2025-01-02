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
    'norcalli/nvim-colorizer.lua',
    config = {
      'toml',
      'lua',
    },
    ft = { 'toml', 'lua' },
  },
}
