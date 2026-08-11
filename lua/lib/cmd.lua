--- Command-line history helpers.
---@class LibCmd
local M = {}

---Command history, most recent first.
---@return string[]
M.get_command_history = function()
  local last = vim.fn.histnr('cmd')
  local result = {}
  for i = last, 1, -1 do
    local entry = vim.fn.histget('cmd', i)
    if entry and entry ~= '' then
      result[#result + 1] = entry
    end
  end
  return result
end

---The most recent command, or '' when history is empty.
---@return string
M.get_last_command = function()
  return vim.fn.histget('cmd', -1) or ''
end

return M
