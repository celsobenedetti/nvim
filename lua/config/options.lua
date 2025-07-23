-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--   /home/celso/local/lazyvim/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.supermaven_inline_completion = true

vim.opt.spelllang = { "en", "pt" }

-- avante.nvim: views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false
