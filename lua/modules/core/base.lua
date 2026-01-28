---@module 'base' module with general core plugins

return {
  -- core plugins
  { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim
  { 'wakatime/vim-wakatime' }, -- code time tracking goodness

  -- json/yaml schema store
  { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } },

  -- lua lsp intellisense for neovim config
  {
    'folke/lazydev.nvim',
    ft = { 'lua' },
    opts = {
      library = {
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types when the `vim.uv` word is found
      },
    },
  },
}
