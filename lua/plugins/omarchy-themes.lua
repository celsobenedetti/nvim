-- this is here simply to prevent these plugins from being cleaned up by LazyVim
return {
  { 'tahayvr/matteblack.nvim', lazy = true, enabled = true },
  { 'EdenEast/nightfox.nvim', lazy = true, enabled = true },
  { 'gthelding/monokai-pro.nvim', lazy = true, enabled = true },
  { 'rebelot/kanagawa.nvim', lazy = true, enabled = true },
  { 'ribru17/bamboo.nvim', lazy = true, enabled = true },
  { 'neanias/everforest-nvim', lazy = true, enabled = true },
  { 'rose-pine/neovim', lazy = true, enabled = true, name = 'rose-pine' },
  { 'ellisonleao/gruvbox.nvim', lazy = true, enabled = true },
  { 'kepano/flexoki-neovim', lazy = true, enabled = true },
  { 'everviolet/nvim', lazy = true, enabled = true, name = 'evergarden' },
  {
    config = function()
      print 'hello'
    end,
  },
}
