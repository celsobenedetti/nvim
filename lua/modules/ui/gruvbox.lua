if 'gruvbox' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

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
        bold = false,
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        inverse = true, -- invert background for search, diffs, statuslines and errors
        contrast = '', -- can be "hard", "soft" or empty string
        overrides = {
          DiffAdd = { bg = '#333e34' },
        },
        dim_inactive = false,
        transparent_mode = false,
        palette_overrides = {
          --gruvbox material colors, easier on the eyes
          bright_orange = '#f28534',
          bright_green = '#a9b665',
          bright_red = '#f2594b',
          bright_yellow = '#e9b143',
        },
      })

      local colors = vim.g.colors
      colors.secondary = '#a4a4a4'
      vim.g.colors = colors

      vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#a9b665' })
    end,
  },
}
