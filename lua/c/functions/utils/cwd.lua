local M = {}

M.is_next = function()
  local root = vim.fs.root(0, 'next.config.ts')
  return not not root
end

M.is_deno = function()
  local root = vim.fs.root(0, '.git')
  local is_next = M.is_next()

  if not root then
    return false
  end

  return not is_next and vim.fn.filereadable(root .. '/deno.json') ~= 0
end

M.is_tailwind = function()
  local root = vim.fs.root(0, 'tailwind.config.ts')
  return not not root
end

return M
