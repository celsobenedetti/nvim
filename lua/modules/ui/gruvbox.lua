return {
  {
    'ellisonleao/gruvbox.nvim',
    config = function()
      require('gruvbox').setup({
        palette_overrides = {
          bright_green = '#a9b665', --gruvbox material
          -- bright_green = '#b0b846', -- gruvbox material "mix" variant
        },
      })
    end,
  },
}
