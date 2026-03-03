local M = {}

M.goto_current_task = function()
  local org = require('orgmode')
  org.clock:org_clock_goto()
  vim.cmd('TwilightEnable')
end

return M
