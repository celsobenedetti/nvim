--- Fugitive patch buffers (`filetype=git`): `:Git diff` / show / log -p.
--- Navigation via the `diff` treesitter grammar (aliased onto `git` in
--- after/plugin/autocmds.lua):
---   `[` / `]`  previous / next hunk   (`@@` section)
---   `,` / `.`  previous / next file   (`diff --git` block)
---
--- These are buffer-local: the patch buffer is `buftype=nowrite`, so the
--- normal-mode `.` (repeat) has nothing to repeat, and `,` (reverse `f`/`t`)
--- is re-used here for block navigation.

local function nav(kind, dir)
  return function()
    lib.Diff.goto_node(kind, dir)
  end
end

vim.keymap.set('n', ']', nav('hunk', 1), { buffer = 0, desc = 'diff: next hunk' })
vim.keymap.set('n', '[', nav('hunk', -1), { buffer = 0, desc = 'diff: previous hunk' })
vim.keymap.set('n', '.', nav('block', 1), { buffer = 0, desc = 'diff: next file' })
vim.keymap.set('n', ',', nav('block', -1), { buffer = 0, desc = 'diff: previous file' })
