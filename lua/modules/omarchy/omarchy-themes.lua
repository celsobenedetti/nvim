local omarchy_colorscheme = require('lib.colors').omarchy_colorscheme()

if not omarchy_colorscheme or not omarchy_colorscheme.colorscheme or not omarchy_colorscheme.colorscheme_plugin then
  return {}
end

return {
  -- add plugin from omarchy current theme and set colorscheme
  vim.tbl_extend('keep', omarchy_colorscheme.colorscheme_plugin, {
    init = function()
      vim.cmd('colorscheme ' .. omarchy_colorscheme.colorscheme)
    end,
  }),

  -- these are here simply to prevent these plugins from being cleaned up by lazy.nvim

  { 'oskarnurm/koda.nvim', lazy = true, enabled = true },
  { 'blazkowolf/gruber-darker.nvim', lazy = true, enabled = true },
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
}
