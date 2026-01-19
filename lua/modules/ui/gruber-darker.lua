return {
  {
    'blazkowolf/gruber-darker.nvim',
    config = function()
      require('gruber-darker').setup()

      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'gruber-darker',
        callback = function()
          -- vim.api.nvim_set_hl(0, 'GruberDarkerDarkNiagara', { link = 'GruberDarkerNiagara' })
        end,
      })
    end,
  },
}
