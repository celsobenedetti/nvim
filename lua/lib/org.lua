--- Org-mode helpers wired up by after/ftplugin/org.lua.
---
---@class LibOrg
local M = {}

--- `n` in an org buffer: while a search is highlighted it keeps its builtin
--- meaning (jump to the next match), otherwise it adds a note to the headline.
M.add_note_or_search_next = function()
  if vim.v.hlsearch == 1 then
    vim.cmd('normal! n')
    return
  end
  require('orgmode').action('org_mappings.add_note')
end

return M
