local ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

return {
  { 'dmmulroy/ts-error-translator.nvim', ft = ft, config = true },
  {
    'pmizio/typescript-tools.nvim',
    lazy = function()
      return C.cwd.is_deno()
    end,
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {},
    ft = ft,
  },
}
