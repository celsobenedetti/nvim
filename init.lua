require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.editor' },
    { import = 'modules.overseer' },
    { import = 'modules.ui' },
    { import = 'modules.zk' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { import = 'plugins' },
    { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim
    { 'wakatime/vim-wakatime' }, -- code time tracking goodness
    { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } }, -- json/yaml schema store

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
  },
  change_detection = { notify = false },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  },
  performance = vim.g.lazy_nvim_config.performance,
})

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.undotree')
