local M = {}

--- @param msg string
local function notify(msg)
  Snacks.notify.info(msg, { title = 'toggle' })
end

M.completion = function()
  vim.g.completion = not vim.g.completion
  notify(string.format('completion: %q', vim.g.completion))
end

M.supermaven = function()
  vim.cmd('SupermavenToggle')
  notify('toggle: supermaven')
end

M.autoformat = function()
  vim.g.autoformat = not vim.g.autoformat
  notify(string.format('autoformat: %q', vim.g.autoformat))
end

return M
