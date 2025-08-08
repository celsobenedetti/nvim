local M = {}

--- Reads the AI Rules file and returns the contents
---@return string
M.the_engineer = function()
  local file = io.open(vim.g.notes.AI_RULES)
  if not file then
    return 'Something went wrong with setup, simply reply with: "TheEngineer has failed to load!", and to no further actions'
  end

  return file:read '*all'
end

return M
