return {
  {
    'blazkowolf/gruber-darker.nvim',
    config = function()
      vim.schedule(function()
        vim.g.hl.text.secondary = '@string.special'

        local colors = require('lib.colors')
        vim.api.nvim_set_hl(0, 'TabLine', { fg = colors.get_color('Comment', 'fg') })

        vim.api.nvim_set_hl(0, 'TabLineSel', { fg = colors.get_color('GruberDarker_Yellow', 'fg') })
        vim.api.nvim_set_hl(0, '@lsp.type.operator', { link = 'Macro' })
      end)
    end,
  },
}
