local M = {}

-- spawn a window on the bottom of the screen with a :term buffer
---@param buffer? number the buffer to attach to window
---@return number - the window id
M.below = function(buffer)
  local buf = buffer or vim.api.nvim_create_buf(false, true)
  local columns = vim.api.nvim_get_option_value("columns", {})
  local lines = vim.api.nvim_get_option_value("lines", {})
  local win_height = math.max(8, math.floor(lines * vim.g.below_split_height))
  local win = vim.api.nvim_open_win(buf, true, {
    split = "below",
    width = columns,
    height = win_height,
    style = "minimal",
  })

  return win
end

-- spawn a window on the bottom of the screen with a :term buffer
-- this is a "float" window, which unfortunately does not behave like a splits.
-- to navigate to the float window, we need some workaround like nvim_set_current_win
--
-- really the only reason I use this is vibes based, because the "border" decoration looks so nice
--
---@param buffer? number the buffer to attach to window
---@return number - the window id
M.relative_below = function(buffer, opts)
  local buf = buffer or vim.api.nvim_create_buf(false, true)
  local api = vim.api
  local columns = vim.api.nvim_get_option_value("columns", {})
  local lines = vim.api.nvim_get_option_value("lines", {})
  local win_height = math.max(8, math.floor(lines * vim.g.below_split_height))
  local win_opts = {
    relative = "editor",
    row = lines - win_height,
    col = 0,
    width = columns,
    height = win_height,
    style = "minimal",
    border = "single",
  }

  local ok, win = pcall(api.nvim_open_win, buf, true, win_opts)
  if not ok then
    -- WARN: this sure looks like an infinite loop vector.
    -- I'm trusting nvim_open_win will always have a valid buffer from nvim_create_buf
    buf = api.nvim_create_buf(false, true)
    return M.relative_below(buf, opts)
  end

  return win
end

return M
