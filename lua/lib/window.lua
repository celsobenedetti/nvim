local M = {}

-- spawn a window on the bottom of the screen with a :term buffer
---@param buffer? number the buffer to attach to window
---@return number - the window id
M.below = function(buffer)
  local buf = buffer or vim.api.nvim_create_buf(false, true)
  local columns = vim.api.nvim_get_option_value("columns", {})
  local lines = vim.api.nvim_get_option_value("lines", {})
  local win_height = math.max(8, math.floor(lines * 0.34))
  local win = vim.api.nvim_open_win(buf, true, {
    split = "below",
    width = columns,
    height = win_height,
    style = "minimal",
  })

  return win
end

return M
