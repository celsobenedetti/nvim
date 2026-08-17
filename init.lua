require('init')

require('lazy').setup({
  spec = {
    { import = 'plugins' },
    { import = 'plugins.secondary' },

    { 'neovim/nvim-lspconfig' },                                                   -- install lspconfig through lazy.nvim
    { 'wakatime/vim-wakatime' },                                                   -- code time tracking goodness
    { 'b0o/SchemaStore.nvim',      lazy = true, ft = { 'json', 'yaml', 'toml' } }, -- json/yaml schema store

    {
      'folke/lazydev.nvim', -- lua lsp intellisense for neovim config
      ft = { 'lua' },
      opts = {
        library = {
          { path = 'snacks.nvim',        words = { 'Snacks' } },
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } }, -- Load luvit types when the `vim.uv` word is found
        },
      },
    },
  },
  -- disabled: polls every file under lua/plugins/** every 2s and, on change,
  -- synchronously reloads all plugin specs on the main loop. Editing any
  -- plugin config file while a terminal-backed UI (fzf-lua, etc.) is open
  -- stalls the event loop mid-redraw and corrupts its screen buffer.
  change_detection = { enabled = false },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  },
  performance = config.lazy_nvim_config.performance,
})

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.undotree')
