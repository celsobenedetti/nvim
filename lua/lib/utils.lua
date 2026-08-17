local M = {}

M.statusline = function()
  local branch = vim.trim(vim.fn.system('git branch --show-current'))
  return branch .. ' ' .. vim.fn.expand('%')
end

return M
