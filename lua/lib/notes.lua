---@class LibNotes
local M = {}

--- @param fn function? to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  if lib.tab.create_or_focus(config.tabs.notes) then
    vim.cmd.lcd(config.dirs.notes)
    vim.cmd.tabmove('$')
  end

  if fn then
    vim.schedule(function()
      -- nvim started with `-p` (neovide's default) reselects the first tab
      -- after plugins load, undoing the focus above; re-assert it before
      -- filling the tab.
      local notes = lib.tab.find(config.tabs.notes)
      if notes then
        vim.api.nvim_set_current_tabpage(notes)
      end
      fn()
    end)
  end
end

M.is_notes_dir = function()
  return vim.fn.getcwd():find(config.dirs.notes)
end

return M
