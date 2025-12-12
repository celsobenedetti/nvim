local M = {}

M.statuscolumn = function()
  return package.loaded.snacks and require('snacks.statuscolumn').get() or ''
end

M.statusline = function()
  local branch = vim.trim(vim.fn.system('git branch --show-current'))
  return branch .. ' ' .. vim.fn.expand('%')
end

return M
