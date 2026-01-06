local M = {}

local TAB_NAME = 'notes'

--- @param fn function to be called after tab is created or focus
M.focus_or_create_notes_tab = function(fn)
  local tab_id = -1
  local tabs = vim.api.nvim_list_tabpages()
  local has_tabby, tab_name = pcall(require, 'tabby.feature.tab_name')
  if has_tabby then
    for _, tab in ipairs(tabs) do
      if tab_name.get(tab):find(TAB_NAME) then
        tab_id = tab
      end
    end
  end

  if tab_id == -1 then
    vim.cmd('tabnew')
    vim.g.fn.rename_tab(vim.g.icons.notes .. TAB_NAME)
    vim.cmd('lcd ' .. vim.g.env.notes.NOTES)
  else
    local win_id = vim.api.nvim_tabpage_get_win(tab_id)
    vim.api.nvim_set_current_win(win_id)
  end

  if fn then
    vim.schedule(fn)
  end
end

return M
