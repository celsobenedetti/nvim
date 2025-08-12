if os.getenv 'PERF' == 'true' then
  vim.g.performance = true
end

map = vim.keymap.set

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

local colors = require 'config.colors'
vim.g.colors = colors.evergarden
vim.g.colorscheme = colors.colorscheme
vim.g.background = colors.background
vim.g.notes = require 'config.zk' -- NOTES config
