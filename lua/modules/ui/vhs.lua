local overrides = {
  ['@lsp.mod.readonly'] = { link = '@lsp.type.variable' },
}

return {
  {
    'mistweaverco/vhs-era-theme.nvim',
    enabled = vim.g.colorscheme == 'vhs-era-theme',
    init = function()
      vim.cmd('colorscheme vhs-era-theme')
      for hl, val in pairs(overrides) do
        vim.api.nvim_set_hl(0, hl, val)
      end
    end,
  },
}
