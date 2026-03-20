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

      vim.schedule(function()
        local colors = require('deepwhite.colors').get_colors({})

        vim.api.nvim_set_hl(0, 'Constant', { bg = colors['base6'] })
        vim.api.nvim_set_hl(0, 'String', { fg = colors['green'] })
        vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = colors['green'], bg = 'None' })
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
