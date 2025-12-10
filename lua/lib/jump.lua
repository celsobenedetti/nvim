local M = {}

--- Sets a mark at the current position before doing a relative jump
--- Adding it to the jump list
---@param key string which key was pressed (j or k)
local relative_jump_with_mark = function(key)
  local count = vim.v.count or 1
  local orig_key = vim.api.nvim_replace_termcodes(key, true, true, true)

  -- if doing relative jump, add current position to jump list
  if count > 1 then
    vim.api.nvim_feedkeys("m'", 'n', true)
  end
  vim.api.nvim_feedkeys(count .. orig_key, 'n', true)
end

M.up = function()
  relative_jump_with_mark('k')
end

M.down = function()
  relative_jump_with_mark('j')
end

M.diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({
      severity = severity,
      count = next and 1 or -1,
      float = true,
    })
  end
end

return M
