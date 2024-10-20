local M = {}

M.is_deno = function()
  local root = vim.fs.root(0, '.git')

  if not root then
    return false
  end

  return vim.fn.filereadable(root .. '/deno.json') ~= 0
end

return M
