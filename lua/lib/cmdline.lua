local M = {}

-- clear cmdline after 5s
M.clear = function()
  vim.fn.timer_start(5000, function()
    print(' ')
  end)
end

return M
