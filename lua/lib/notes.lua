---@class LibNotes
local M = {}
local tab = lib.tab

local TABNAME = config.icons.notes .. 'notes'

--- @param fn function? to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  local tab_id = tab.find(TABNAME)

  if not tab_id then
    vim.cmd.tabnew()
    tab.rename(TABNAME)
    vim.cmd.lcd(config.env.notes.NOTES)
    vim.cmd.tabmove('$')
  else
    vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab_id))
  end

  if fn then
    vim.schedule(fn)
  end
end

M.is_notes_dir = function()
  return vim.fn.getcwd():find(config.env.notes.NOTES)
end

return M
