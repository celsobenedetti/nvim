return {
  { 'levouh/tint.nvim', opts = true }, -- Slightly tint unfocused pane

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
    'norcalli/nvim-colorizer.lua',
    lazy = true,
    ft = {
      'toml',
      'lua',
    },
    config = {
      'toml',
      'lua',
    },
  },
}
