--- @module 'hunk'
--- hunk (https://hunk.dev) diff viewer, in its own tabpage.

--- $EDITOR of the hunk job: hunk's `e` (hunk.review.editSelectedFile) spawns
--- it with the selected file and line, and the shim forwards both to this
--- Neovim (lib.hunk.open) instead of nesting an editor inside the terminal.
local EDITOR = vim.fn.stdpath('config') .. '/scripts/hunk-editor/nvim'

--- Open `hunk diff` in its own tabpage. If a hunk tab already exists, jump to
--- it instead of opening a duplicate.
local function hunk_tab()
  local tabid = lib.tab.find('hunk')
  if tabid then
    vim.api.nvim_set_current_tabpage(tabid)
    return
  end

  vim.cmd('tabnew')
  lib.tab.rename('hunk')
  tabid = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()

  vim.fn.jobstart({ 'hunk', 'diff' }, {
    term = true,
    cwd = lib.cwd.root(),
    env = { EDITOR = EDITOR },
    -- close the hunk tab when hunk quits, even if the user navigated to
    -- another tab in the meantime, and wipe the dead terminal buffer with it.
    on_exit = function()
      if vim.api.nvim_tabpage_is_valid(tabid) and #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd(vim.api.nvim_tabpage_get_number(tabid) .. 'tabclose')
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })
end

vim.keymap.set('n', '<leader>hu', hunk_tab, { desc = 'hunk: (tab) Root Dir' })
