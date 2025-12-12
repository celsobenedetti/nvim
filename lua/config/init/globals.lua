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

local ok, devicons = pcall(require, 'nvim-web-devicons')
function _G.MyStatusLine()
  local branch = vim.trim(vim.fn.system('git branch --show-current'))
  local relative_file = vim.fn.expand('%:.')

  local icon = ''
  if ok then
    icon = devicons.get_icon(relative_file) or ''
  end

  return '  ' .. branch .. '%=' .. icon .. ' ' .. relative_file .. '%=%='
end
