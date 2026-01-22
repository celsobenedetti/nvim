return {
  {
    'blazkowolf/gruber-darker.nvim',
    config = function()
      require('gruber-darker').setup()

      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'gruber-darker',
        callback = function()
          local colors = require('lib.colors')
          vim.api.nvim_set_hl(0, 'TabLine', { fg = colors.get_color('Comment', 'fg') })
          vim.api.nvim_set_hl(0, 'TabLineSel', { fg = colors.get_color('GruberDarker_Yellow', 'fg') })
        end,
      })
    end,
  },
}
