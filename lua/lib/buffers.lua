local M = {}

M.get_valid_bufs = function()
  local bufs = vim.api.nvim_list_bufs()
  local valid_bufs = {}
  for _, buf in ipairs(bufs) do
    if
      vim.api.nvim_get_option_value('buftype', { buf = buf }) ~= 'nofile'
      -- and vim.api.nvim_get_option_value('buftype', { buf = buf }) ~= 'terminal'
    then
      table.insert(valid_bufs, buf)
    end
  end
  return valid_bufs
end

return M
