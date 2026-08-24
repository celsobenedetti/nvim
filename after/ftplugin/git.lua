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

-- Left-side tree of the file/hunk sections (lib.Diff.open_tree).
vim.keymap.set('n', 'glt', function()
  lib.Diff.open_tree()
end, { buffer = 0, desc = 'diff: toggle file/hunk tree' })

-- Inline filepath bars for `diff --git` header lines (lib.diff_filepath).
-- Fugitive creates the buffer and sets filetype=git BEFORE its job streams
-- the diff into it, so a once-only render at FileType time would be a no-op:
-- attach on_lines and replan per event-loop tick (same pattern the old
-- word-diff emphasis used). The extmark namespace is `nvim.diff_filepath`, so
-- nvim-treesitter-context mirrors the bar into its sticky context window.
if not vim.b.diff_filepath_setup then
  vim.b.diff_filepath_setup = true
  local bufnr = vim.api.nvim_get_current_buf()
  local diff_filepath = require('lib.diff_filepath')

  local pending = false
  local function replan()
    if pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      if vim.api.nvim_buf_is_valid(bufnr) then
        diff_filepath.render(bufnr)
      end
    end)
  end

  replan()
  vim.api.nvim_buf_attach(bufnr, false, { on_lines = replan })
end
