return {
  {
    'rose-pine/neovim',
    config = function()
      require('rose-pine').setup({
        highlight_groups = {
          TabLine = { bg = 'gold' },
        },
      })

      -- vim.schedule(function()
      --   vim.api.nvim_set_hl(0, 'TabLineSel', { link = '@comment.note' })
      -- end)
    end,
  },
}
