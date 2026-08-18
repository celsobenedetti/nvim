---@class LibJump
local M = {}

--- Sets a mark at the current position before doing a relative jump
--- Adding it to the jump list
---@param key string which key was pressed (j or k)
---@param visual_key string the visual mode key (gj or gk)
local function relative_jump_with_mark(key, visual_key)
  local count = vim.v.count or 0

  if count > 0 then
    vim.cmd('norm! ' .. count .. key)
  else
    vim.cmd('norm! ' .. visual_key)
  end
end

M.up = function()
  relative_jump_with_mark('k', 'gk')
end

M.down = function()
  relative_jump_with_mark('j', 'gj')
end

return M
