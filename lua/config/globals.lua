if os.getenv 'PERF' == 'true' then
  vim.g.performance = true
end

map = vim.keymap.set

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

local env = require 'config.env' -- NOTES config
vim.g.env = env
vim.g.notes = env.notes -- NOTES config
vim.g.dirs = require 'config.dirs' -- NOTES config
