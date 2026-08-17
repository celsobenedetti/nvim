--- Key-notation helpers.
---@class LibKeys
local M = {}

---Replace key notation (e.g. '<esc>') with the byte sequence nvim_feedkeys expects.
---@param str string
---@return string
M.termcodes = function(str)
  return vim.api.nvim_replace_termcodes(str, false, false, true)
end

return M
