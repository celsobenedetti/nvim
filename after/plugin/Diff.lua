--- @module "Diff"
--- Simple user command `:Diff` designed to be a simple git viewer.
--- Simple premise:
--- 1. diff as regular buffer with `filetype=git`
--- 2. quickfix entry for each file affected
---
--- We use vim-fugitive's `:Git` primitive to get diff in regular, navigable, `filetype` buffer.
--- Single buffer with whole diff.
--- The treesitter `diff` grammar (aliased onto `git` in after/plugin/autocmds.lua)
--- locates each per-file `block`; one quickfix entry per block points at its
--- `diff --git` header line (see lua/lib/Diff.lua).
---
--- Usages:
--- `:Diff`                          -> `Git diff` working tree
--- `:Diff <rev>`                    -> `Git show <rev>`
--- `:Diff <rev1> <rev2>`            -> `Git diff <rev1> <rev2>`
--- `:Diff <rev1>..<rev2>`           -> `Git diff <rev1>..<rev2>`
--- `:Diff <rev1>...<rev2>`          -> `Git diff <rev1>...<rev2>`

-- The canonical `:Diff` (an old duplicate once lived in after/plugin/git.lua;
-- nvim_create_user_command silently replaces, and git.lua sources later, so
-- the stale one could shadow this definition). force keeps the intent clear.
vim.api.nvim_create_user_command('Diff', function(opts)
  local args = lib.strings.split_args(opts.args)
  if #args > 2 then
    vim.notify('Usage: :Diff [rev] [rev2]', vim.log.levels.WARN)
    return
  end
  lib.Diff.open(args)
end, { nargs = '*', force = true, desc = 'git: diff working tree, show <rev>, or diff <rev1> <rev2> (tab + quickfix)' })
