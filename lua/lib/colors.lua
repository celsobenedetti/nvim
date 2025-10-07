local M = {}

--- get value for attribute of highlight group
---
--- :h synIDattr
---@param hl_group string highlight group
---@param attr string highlight attribute
M.get_color = function(hl_group, attr)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(hl_group)), attr)
end

return M
