---@class LibNotes
local M = {}
local tab = require('lib.tab')

--- @param fn function? to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  local tab_id = tab.find(vim.g.notes_tabname)

  if not tab_id then
    vim.cmd.tabnew()
    tab.rename(vim.g.notes_tabname)
    vim.cmd.lcd(vim.g.env.notes.NOTES)
    vim.cmd.tabmove('$')
  else
    vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab_id))
  end

  if fn then
    vim.schedule(fn)
  end
end

M.is_notes_dir = function()
  return vim.fn.getcwd():find(vim.g.env.notes.NOTES)
end

return M
