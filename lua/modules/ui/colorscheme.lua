return {
  -- { 'catppuccin/nvim' },
  { 'ellisonleao/gruvbox.nvim', priority = 1000, config = true, lazy = true },
  {
    'rose-pine/neovim',
    lazy = true,
    name = 'rose-pine',
    opts = {
      styles = { italic = false },
    },
  },
  {
    'projekt0n/github-nvim-theme',
    lazy = true, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = true,
  },
}
