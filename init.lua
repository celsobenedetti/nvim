require('init')

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.undotree')

require('lazy').setup(vim.tbl_deep_extend('force', config.lazy, {
  spec = {
    { import = 'plugins' },
    { import = 'plugins.secondary' },

    { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim
    { 'wakatime/vim-wakatime' }, -- code time tracking goodness
    { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } }, -- json/yaml schema store

    {
      'folke/lazydev.nvim', -- lua lsp intellisense for neovim config
      ft = { 'lua' },
      opts = {
        library = {
          { path = 'snacks.nvim', words = { 'Snacks' } },
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types when the `vim.uv` word is found
        },
      },
    },
  },
}))
