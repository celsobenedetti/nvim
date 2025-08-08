local M = {}

--- Reads the AI Rules file and returns the contents
---@return string
M.the_engineer = function()
  local file = io.open(vim.g.notes.AI_RULES)
  if not file then
    return 'ERROR: whatever the prompt, reply only: "TheEngineer has failed to load!"'
  end

  return file:read '*all'
end

return M
