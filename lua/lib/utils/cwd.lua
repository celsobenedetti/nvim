local M = {}

M.is_next = function()
  local root = vim.fs.root(0, 'next.config.ts')
  return not not root
end

M.is_deno = function()
  local root = vim.fs.root(0, 'deno.json')
  local is_next = M.is_next()

  if not root then
    return false
  end

  return not is_next
end

M.is_tailwind = function()
  return true
  -- local tailwind_file = not not vim.fs.root(0, 'tailwind.config.ts')
  -- local vite_file = not not vim.fs.root(0, 'vite.config.ts')
  --
  -- return tailwind_file or vite_file
end

M.is_work = function()
  local path = vim.fn.expand '%:p'
  return path:find 'chatbot'
end

M.is_llm_chats = function()
  local path = vim.fn.expand '%:p'
  return path:find '.local/chats'
end

return M
