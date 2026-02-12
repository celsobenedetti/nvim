local M = {}

--- launches new window with command
---@param cmd string
---@param opts? table
M.neww = function(cmd, opts)
  opts = opts or {}
  if opts.name then
    cmd = string.format('-n "%s" %s', opts.name, cmd)
  end

  vim.cmd('silent! !tmux neww  ' .. cmd .. '')
end

return M
