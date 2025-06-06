return {
  { lazy = true, 'catppuccin/nvim' },
  { lazy = false, 'everviolet/nvim', name = 'evergarden', priority = 1000, opts = require 'config.ui.evergarden' },
  { lazy = true, 'olivercederborg/poimandres.nvim', priority = 1000, opts = true },
  { lazy = true, 'rebelot/kanagawa.nvim' },
  { lazy = true, 'datsfilipe/vesper.nvim' },
  { lazy = true, 'nyoom-engineering/oxocarbon.nvim' },
  { lazy = true, 'ellisonleao/gruvbox.nvim', priority = 1000, config = true },
  { lazy = true, 'projekt0n/github-nvim-theme', priority = 1000, opts = true },
  { lazy = true, 'rose-pine/neovim', name = 'rose-pine', opts = { styles = { italic = false } } },
  { lazy = true, 'webhooked/kanso.nvim', priority = 1000 },
  { lazy = true, 'dgox16/oldworld.nvim', priority = 1000 },
  { lazy = true, 'aliqyan-21/darkvoid.nvim' },
  { lazy = true, 'kvrohit/rasmus.nvim', priority = 1000 },
  { lazy = true, 'drewxs/ash.nvim', priority = 1000 },
  { lazy = true, 'slugbyte/lackluster.nvim', priority = 1000 },
}
