return {
  {
    'ellisonleao/gruvbox.nvim',
    config = function()
      require('gruvbox').setup({
        italic = {
          strings = true,
          emphasis = false,
          comments = false,
          operators = false,
          folds = false,
        },
        terminal_colors = true, -- add neovim terminal colors
        undercurl = true,
        underline = true,
        bold = true,
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        inverse = true, -- invert background for search, diffs, statuslines and errors
        contrast = '', -- can be "hard", "soft" or empty string
        overrides = {},
        dim_inactive = false,
        transparent_mode = false,
        palette_overrides = {
          bright_green = '#a9b665', --gruvbox material
          -- bright_green = '#b0b846', -- gruvbox material "mix" variant
        },
      })
    end,
  },
}
