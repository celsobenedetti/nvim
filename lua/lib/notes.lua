---@class LibNotes
local M = {}

--- @param fn function? to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  local tab_id = lib.tab.find(config.tabs.notes)

  if not tab_id then
    vim.cmd.tabnew()
    lib.tab.rename(config.tabs.notes)
    vim.cmd.lcd(config.dirs.notes)
    vim.cmd.tabmove('$')
  else
    vim.api.nvim_set_current_win(vim.api.nvim_tabpage_get_win(tab_id))
  end

  if fn then
    vim.schedule(fn)
  end
end

M.is_notes_dir = function()
  return vim.fn.getcwd():find(config.dirs.notes)
end

return M
