local M = {}

M.completion = function()
  vim.g.completion = not vim.g.completion
  Snacks.notify(string.format("completion: %q", vim.g.completion))
end

return M
