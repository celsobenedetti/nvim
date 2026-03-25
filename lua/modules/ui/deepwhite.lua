if 'deepwhite' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

return {
  {
    'Verf/deepwhite.nvim',
    -- enabled = false,
    priority = 1000,
    config = function()
      require('deepwhite').setup({})

      local colors = vim.g.colors
      colors.red = colors.color1
      colors.green = colors.color2
      colors.orange = colors.color3
      colors.light_orange = '#FAE1C8' -- hsv(30, 20%, 98%)
      colors.light_yellow = '#FAFAC8' -- hsv(60, 20%, 98%)
      colors.light_cyan = '#C8FAFA' -- hsv(180, 20%, 98%)
      colors.light_green = '#D4FAD4' -- hsv(120, 15%, 98%)
      colors.light_blue = '#D4D4FA' -- hsv(240, 15%, 98%)
      colors.light_purple = '#EDD4FA' -- hsv(280, 15%, 98%)
      colors.light_pink = '#FAD4ED' -- hsv(320, 15%, 98%)
      colors.light_red = '#FAD4D4' -- hsv(360, 15%, 98%)
      colors.light_gray = '#E6E4DF'
      colors.secondary = '#595855'

      vim.g.colors = colors

      vim.schedule(function()
        vim.api.nvim_set_hl(0, 'ColorColumn', { bg = 'None' })
        -- vim.api.nvim_set_hl(0, 'Constant', { bg = 'None' })
        -- vim.api.nvim_set_hl(0, 'Statement', { bg = colors.light_red })
        vim.api.nvim_set_hl(0, 'String', { fg = colors['green'] })
        vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = colors['green'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = colors['orange'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = colors['red'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'GitSignsStagedAdd', { fg = colors['light_green'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'GitSignsStagedChange', { fg = colors['light_orange'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'GitSignsStagedDelete', { fg = colors['light_red'], bg = 'None' })
        vim.api.nvim_set_hl(0, 'EchoNotificationInfo', { fg = colors['base0'] })
        vim.api.nvim_set_hl(0, 'NotificationError', { fg = colors['base0'] })
      end)
    end,
    dependencies = {
      {
        'esmuellert/codediff.nvim',
        opts = {
          highlights = {
            line_insert = '#D4FAD4',
            line_delete = '#FAD4D4',
          },
        },
      },
    },
  },
}
