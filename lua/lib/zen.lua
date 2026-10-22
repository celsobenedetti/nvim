--- Tab-exclusive zen mode: every tab owns its own zen window.
---
--- `Snacks.zen` keeps its window in a module singleton and closes it when it is
--- reopened, and its "close when another window is entered" autocmd also fires
--- on a tab switch (a tab switch enters a window). Both are worked around here.
local M = {}

---@type table<number, snacks.win> tabpage id -> its zen window
local wins = {}

--- The zen window of a tab, if still open.
---@param tabid? number
---@return snacks.win?
function M.get(tabid)
  tabid = tabid or vim.api.nvim_get_current_tabpage()
  local win = wins[tabid]
  if win and win:win_valid() then
    return win
  end
  wins[tabid] = nil
end

--- Is any zen window open, in any tab?
function M.any()
  for tabid in pairs(wins) do
    if M.get(tabid) then
      return true
    end
  end
  return false
end

--- Toggle zen for the current tab, keeping other tabs' zen open.
---@param opts? snacks.zen.Config
function M.toggle(opts)
  opts = vim.tbl_extend('force', {}, opts or {}) -- never mutate the caller's table
  local tabid = vim.api.nvim_get_current_tabpage()

  local win = M.get(tabid)
  if win then
    win:close()
    return
  end

  -- forget the singleton so it does not close the zen of another tab
  Snacks.zen.win = nil

  local close = opts.on_close
  opts.on_close = function(w)
    wins[tabid] = nil -- also runs when the tab itself is closed
    if close then
      close(w)
    end
  end

  local zen_win = Snacks.zen(opts)
  wins[tabid] = zen_win

  -- snacks closes zen whenever another window is entered, and switching tabs is
  -- such an entry. Keep that, but only for windows of *this* tab. Zen registers
  -- its autocmd before returning, so this has to run after the call.
  -- shortcut: pokes snacks' own autocmd group, revisit on snacks updates
  for _, au in ipairs(vim.api.nvim_get_autocmds({ group = zen_win.augroup, event = 'WinEnter' })) do
    pcall(vim.api.nvim_del_autocmd, au.id)
  end
  zen_win:on('WinEnter', function(w)
    if not w:win_valid() then
      return
    end
    local cur = vim.api.nvim_get_current_win()
    if
      cur ~= w.win
      and vim.api.nvim_win_get_config(cur).relative == ''
      and vim.api.nvim_win_get_tabpage(cur) == tabid
    then
      vim.schedule(function()
        w:close()
      end)
    end
  end)

  return zen_win
end

return M
