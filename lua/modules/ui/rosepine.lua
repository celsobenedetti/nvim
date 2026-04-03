if 'rose-pine-dawn' ~= require('lib.colors').omarchy_colorscheme().colorscheme then
  return {}
end

return {
  {
    'rose-pine/neovim',
    config = function()
      require('rose-pine').setup({
        highlight_groups = {
          TabLine = { bg = 'gold' },
          String = { fg = vim.g.colors.accent },
          ['@variable'] = { link = 'Normal' },
        },
      })

      -- vim.schedule(function()
      --   vim.api.nvim_set_hl(0, 'TabLineSel', { link = '@comment.note' })
      -- end)
    end,
  },
}
