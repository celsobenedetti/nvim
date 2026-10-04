--- @module 'hunk'
--- hunk (https://hunk.dev) diff viewer, in its own tabpage.

--- $EDITOR of the hunk job: hunk's `e` (hunk.review.editSelectedFile) spawns
--- it with the selected file and line, and the shim forwards both to this
--- Neovim (lib.hunk.open) instead of nesting an editor inside the terminal.
local EDITOR = vim.fn.stdpath('config') .. '/scripts/hunk-editor/nvim'

--- Tab showing exactly this `hunk diff` invocation. lib.tab.find matches
--- substrings, so it would hand plain `:Hunk` the `hunk --cached` tab; each
--- variant gets its own tab, hence whole-name matching.
---@param name string
---@return number? tabid
local function find_tab(name)
  for _, tabid in ipairs(vim.api.nvim_list_tabpages()) do
    if lib.tab.get_name(tabid) == name then
      return tabid
    end
  end
end

--- Open `hunk diff <args>` in its own tabpage. If a tab for the same args
--- already exists, jump to it instead of opening a duplicate.
---@param args string[] extra `hunk diff` arguments: `--cached`, a revision, ...
local function hunk_tab(args)
  local name = table.concat(vim.list_extend({ 'hunk' }, args), ' ')
  local tabid = find_tab(name)
  if tabid then
    vim.api.nvim_set_current_tabpage(tabid)
    return
  end

  vim.cmd('tabnew')
  lib.tab.rename(name)
  tabid = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()

  vim.fn.jobstart(vim.list_extend({ 'hunk', 'diff' }, args), {
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

--- `:Hunk`           -> `hunk diff` working tree
--- `:Hunk --cached`  -> `hunk diff --cached` index (alias of `--staged`)
--- `:Hunk <rev>`     -> `hunk diff <rev>`
vim.api.nvim_create_user_command('Hunk', function(opts)
  hunk_tab(lib.strings.split_args(opts.args))
end, {
  nargs = '*',
  desc = 'hunk: review the working tree, the index (--cached), or a <revision> (tab)',
})

vim.keymap.set('n', '<leader>hu', function()
  hunk_tab({})
end, { desc = 'hunk: (tab) Root Dir' })
