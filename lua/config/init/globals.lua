if os.getenv('PERF') == 'true' then
  vim.g.performance = true
end

---@diagnostic disable-next-line: lowercase-global
map = vim.keymap.set

Keys = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

vim.g.env = require('config.env')
vim.g.dirs = require('config.dirs')
vim.g.colors = require('config.colors').default
