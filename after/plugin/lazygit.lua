--- @module 'lazygit'
--- lazygit integration using Snacks

--- Find the tabpage whose window shows `buf`.
---@param buf number
---@return number? tabpage when the buffer is not displayed anywhere
local function tabpage_containing(buf)
  for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return tp
      end
    end
  end
  return nil
end
---
--- Open lazygit in its own tabpage. If a lazygit tab already exists,
--- jump to it instead of opening a duplicate.
local function lazygit_tab()
  local tabid = lib.tab.find('lazygit')
  if tabid then
    vim.api.nvim_set_current_tabpage(tabid)
    return
  end

  vim.cmd('tabnew')
  lib.tab.rename('lazygit')

  local term = Snacks.lazygit({
    cwd = lib.cwd.root(),
    auto_close = false,
    win = {
      position = 'current',
      keys = {
        q = function()
          vim.cmd('tabclose')
        end,
      },
    },
  })

  -- close the lazygit tab (returning to the previous one) when the process
  -- exits, even if the user navigated to another tab in the meantime.
  -- Also wipe the buffer: snacks caches terminals by cmd+cwd and only drops
  -- the cache entry on BufWipeout, so leaving the (dead) buffer around would
  -- make the next lazygit_tab() call reuse it instead of starting fresh.
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = term.buf,
    once = true,
    callback = function()
      local tp = tabpage_containing(term.buf)
      if tp then
        if tp ~= vim.api.nvim_get_current_tabpage() then
          vim.api.nvim_set_current_tabpage(tp)
        end
        vim.cmd('tabclose')
      end
      if vim.api.nvim_buf_is_valid(term.buf) then
        vim.api.nvim_buf_delete(term.buf, { force = true })
      end
    end,
  })
end

Snacks.config.style('lazygit', {
  wo = {
    winhighlight = 'Normal:SnacksTerminalNormal,NormalNC:SnacksTerminalNormalNC,WinBar:SnacksWinBar,WinBarNC:SnacksWinBarNC,FloatTitle:SnacksTitle,FloatFooter:SnacksFooter,WinSeparator:SnacksWinSeparator',
  },
})

vim.keymap.set('n', '<leader>gg', lazygit_tab, { desc = 'lazygit: (tab) Root Dir' })
