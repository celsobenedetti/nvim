local M = {}

M.is_llm_chats = function()
  local path = vim.fn.expand("%:p")
  return path:find(".local/chats")
end

return M
