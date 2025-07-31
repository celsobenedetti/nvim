-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--   /home/celso/local/lazyvim/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.spelllang = { "en", "pt" }
vim.g.completion = true
vim.g.supermaven_inline_completion = true
vim.g.animation = true
vim.g.animation_duration = 40
vim.g.delay = 80 -- delay used to accomodate for animations

--  whether the toggle term will open as a regular split or a relative "floating" window
vim.g.toggle_term_relative = false

vim.g.should_center = {
  on_n = true,
  on_gg = true,
  on_ctrl_d = true,
}

vim.g.grep_ignore = {
  "pnpm-lock.yaml",
  "instascan.min.js",
}

vim.g.web = {
  jira = os.getenv("WORK_JIRA") or "",
}

vim.g.below_split_height = 0.5

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false

local colors = require("config.colors")
vim.g.colors = colors.evergarden
vim.g.colorscheme = colors.colorscheme
vim.g.background = colors.background
vim.g.notes = require("config.zk") -- NOTES config
