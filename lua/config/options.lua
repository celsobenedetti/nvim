-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--   /home/celso/local/lazyvim/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.spelllang = { 'en', 'pt' }
vim.g.completion = true
vim.g.performance = vim.g.performance or false
vim.o.winborder = 'rounded'

vim.g.transparency = true
vim.g.noice = false
vim.g.bufferline = false
vim.g.dropbar = false
vim.g.smear_cursor = true
vim.g.snacks_animate = false

vim.g.scroll = false and not vim.g.performance
vim.g.supermaven_inline_completion = true

vim.g.lazyvim_check_order = false
vim.g.lazyvim_eslint_auto_format = false
vim.g.trouble_lualine = false

vim.g.lualine = {
  enabled = true,
  lsp = false,
}

vim.g.ai = {
  models = {
    gpt = 'gpt-4.1',
  },
}

vim.g.animation_duration = 40
vim.g.delay = 80 -- delay used to accomodate for animations

vim.g.should_center = {
  on_n = true,
  on_gg = false,
  on_ctrl_d = true,
}

vim.g.grep_ignore = {
  'pnpm-lock.yaml',
  'instascan.min.js',
}

vim.g.web = {
  jira = os.getenv 'WORK_JIRA' or '',
}

vim.g.below_split_height = 0.5

-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200
vim.opt.swapfile = false

vim.opt.tabstop = 4 -- Number of spaces tabs count for
vim.opt.shiftwidth = 4 -- Size of an indent - this seems to affect conform

vim.o.cmdheight = 1 -- Height of the command bar
