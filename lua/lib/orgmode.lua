---@class LibOrgmode
local M = {}

local lib = require('lib')

M.goto_current_task = function()
  lib.notes.focus_or_create_notes_tab(function()
    local org = require('orgmode')
    org.clock:org_clock_goto()
    vim.schedule(function()
      vim.cmd('normal zt')
    end)
  end)
end

return M
