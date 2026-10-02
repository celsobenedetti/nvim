require('init')

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

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.undotree')

if vim.g.neovide then
  -- Increase font size with Ctrl + +
  vim.keymap.set({ 'n', 'v' }, '<C-=>', ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>')
  -- Decrease font size with Ctrl + -
  vim.keymap.set({ 'n', 'v' }, '<C-->', ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>')
  -- Reset scale with Ctrl + 0
  vim.keymap.set({ 'n', 'v' }, '<C-0>', ':lua vim.g.neovide_scale_factor = 1<CR>')
end
