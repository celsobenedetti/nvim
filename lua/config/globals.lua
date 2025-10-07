if os.getenv 'PERF' == 'true' then
  vim.g.performance = true
end

map = vim.keymap.set

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

vim.g.colors = require('config.colors').default

vim.g.notes = require 'config.zk' -- NOTES config
vim.g.dirs = require 'config.dirs' -- NOTES config
