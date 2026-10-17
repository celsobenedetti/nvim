--- @module 'hunk'
--- hunk (https://hunk.dev) diff viewer, in its own tabpage.

--- $EDITOR of the hunk job: hunk's `e` (hunk.review.editSelectedFile) spawns
--- it with the selected file and line, and the shim forwards both to this
--- Neovim (lib.hunk.open) instead of nesting an editor inside the terminal.
local EDITOR = vim.fn.stdpath('config') .. '/scripts/hunk-editor/nvim'

--- Open `hunk diff <args>` (or `hunk show <args>`) in its own tabpage. The tab
--- is named after the invocation filling it, so each variant (`hunk`, `hunk
--- --cached`, `hunk <rev>`, `hunk show <rev>`) gets its own tab and a repeated
--- `:Hunk` jumps to the existing one instead of opening a duplicate.
---@param args string[] arguments after `:Hunk`; a leading `show` selects
---  `hunk show` (one commit), everything else goes to `hunk diff`.
local function hunk_tab(args)
  local cmd, name = { 'hunk', 'diff' }, { 'hunk' }
  if args[1] == 'show' then
    cmd[2], name[2] = 'show', 'show'
    table.remove(args, 1)
  end
  vim.list_extend(cmd, args)
  vim.list_extend(name, args)

  if not lib.tab.create_or_focus(table.concat(name, ' ')) then
    return
  end

  local tabid = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()

  vim.fn.jobstart(cmd, {
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

--- `:Hunk`            -> `hunk diff` working tree
--- `:Hunk --cached`   -> `hunk diff --cached` index (alias of `--staged`)
--- `:Hunk <rev>`      -> `hunk diff <rev>` working tree vs a revision
--- `:Hunk show <rev>` -> `hunk show <rev>` a single commit
vim.api.nvim_create_user_command('Hunk', function(opts)
  hunk_tab(lib.strings.split_args(opts.args))
end, {
  nargs = '*',
  desc = 'hunk: review the working tree, the index (--cached), a <revision>, or a commit (show <rev>) (tab)',
})

vim.keymap.set('n', '<leader>hu', function()
  hunk_tab({})
end, { desc = 'hunk: (tab) Root Dir' })
