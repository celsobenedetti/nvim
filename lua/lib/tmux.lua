local M = {}

--- launches new window with command
---@param cmd string
M.neww = function(cmd)
  vim.cmd('silent! !tmux neww  ' .. cmd .. '')
end

return M
