-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--   /home/celso/local/lazyvim/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.spelllang = { "en", "pt" }
vim.g.supermaven_inline_completion = true

vim.g.should_center = {
  on_G = true,
  on_n = false,
  on_ctrl_d = true,
}

vim.g.grep_ignore = {
  "pnpm-lock.yaml",
  "instascan.min.js",
}

vim.opt.laststatus = 3 -- avante.nvim: views can only be fully collapsed with the global statusline

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false
