return {
  {
    'kepano/flexoki-neovim',
    priority = 1000,
    config = function()
      vim.schedule(function()
        local colors = require('flexoki.palette').palette()

        vim.api.nvim_set_hl(0, 'DiffChange', { bg = colors['bg'] })
        vim.api.nvim_set_hl(0, 'DiffAdd', { bg = '#CEFCCE' })
        vim.api.nvim_set_hl(0, 'DiffDelete', { bg = '#FCDEDD' })
      end)
    end,
  },
}
