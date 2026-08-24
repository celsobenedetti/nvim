--- @module "Diff"
--- Simple user commands (`:Diff`, `:DiffQf`) designed to be a simple git viewer.
--- Simple premise:
--- 1. diff as regular buffer with `filetype=git`
--- 2. an index of the files affected, alongside it
---
--- We use vim-fugitive's `:Git` primitive to get diff in regular, navigable, `filetype` buffer.
--- Single buffer with whole diff.
--- The treesitter `diff` grammar (aliased onto `git` in after/plugin/autocmds.lua)
--- locates each per-file `block`; that drives both indexes:
---
--- - `:Diff`   -> DiffTree sidebar on the left, grouped by parent directory
---               (dir header -> its files -> their hunks), focused; hovering a
---               row previews the section (see docs/diff-tree.md).
--- - `:DiffQf` -> quickfix list below, one entry per block pointing at its
---               `diff --git` header line (the pre-tree default).
---
--- Usages (same for both commands):
--- `:Diff`                          -> `Git diff` working tree
--- `:Diff <rev>`                    -> `Git show <rev>`
--- `:Diff <rev1> <rev2>`            -> `Git diff <rev1> <rev2>`
--- `:Diff <rev1>..<rev2>`           -> `Git diff <rev1>..<rev2>`
--- `:Diff <rev1>...<rev2>`          -> `Git diff <rev1>...<rev2>`

--- Shared argument parsing for both commands. `lib.Diff` is resolved inside
--- the callback, not captured here: `lib`'s __index requires the module on
--- first access, and that parses treesitter queries — keep it out of startup.
---@param name string command name, for the usage message
---@param fn 'open' | 'open_qf' lib.Diff entry point
local function diff_command(name, fn)
  return function(opts)
    local args = lib.strings.split_args(opts.args)
    if #args > 2 then
      vim.notify(('Usage: :%s [rev] [rev2]'):format(name), vim.log.levels.WARN)
      return
    end
    lib.Diff[fn](args)
  end
end

-- The canonical `:Diff` (an old duplicate once lived in after/plugin/git.lua;
-- nvim_create_user_command silently replaces, and git.lua sources later, so
-- the stale one could shadow this definition). force keeps the intent clear.
vim.api.nvim_create_user_command('Diff', diff_command('Diff', 'open'), {
  nargs = '*',
  force = true,
  desc = 'git: diff working tree, show <rev>, or diff <rev1> <rev2> (tab + file tree)',
})

vim.api.nvim_create_user_command('DiffQf', diff_command('DiffQf', 'open_qf'), {
  nargs = '*',
  force = true,
  desc = 'git: like :Diff, with a quickfix list of the changed files instead of the tree',
})

-- Left-side tree of the current diff buffer's per-file `block`s and their
-- `hunk`s (see lua/lib/Diff.lua M.open_tree). Toggle: a second call closes it.
vim.api.nvim_create_user_command('DiffTree', function()
  lib.Diff.open_tree()
end, { desc = 'diff: toggle file/hunk tree sidebar (left split)' })
