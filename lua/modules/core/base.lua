---@module base module with general required plugins

return {
  -- core plugins
  { 'wakatime/vim-wakatime' }, -- code time tracking goodness
  { 'neovim/nvim-lspconfig' }, -- install lspconfig through lazy.nvim

  {
    'folke/lazydev.nvim',
    ft = { 'lua' },
    opts = {
      library = {
        { path = 'snacks.nvim', words = { 'Snacks' } },
      },
    },
  },
}
