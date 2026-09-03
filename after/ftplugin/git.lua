vim.wo.number = false
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
    vim.cmd.norm('zt')
  end
end

vim.keymap.set('n', ']]', nav('hunk', 1), { buffer = 0, desc = 'diff: next hunk' })
vim.keymap.set('n', '[[', nav('hunk', -1), { buffer = 0, desc = 'diff: previous hunk' })
vim.keymap.set('n', '.', nav('block', 1), { buffer = 0, desc = 'diff: next file' })
vim.keymap.set('n', ',', nav('block', -1), { buffer = 0, desc = 'diff: previous file' })

-- Folded blocks keep the filepath bar's background instead of flipping to
-- `Folded`: lib.fold_hl stamps each closed fold with the window's fold surface,
-- and 'winhighlight' is what picks that surface per window (DiffFolded, see
-- after/plugin/diff-colors.lua). Kept per buffer-in-window (`vim.wo[0][0]`) and
-- appended so nothing else already in 'winhighlight' is lost.
local wh = vim.wo[0][0].winhighlight
if not wh:find('Folded:', 1, true) then
  vim.wo[0][0].winhighlight = wh == '' and 'Folded:DiffFolded' or (wh .. ',Folded:DiffFolded')
end

-- Treesitter folds (the `diff` grammar's folds.scm captures `block`, `hunks`,
-- `hunk`) drive `zc`/`za` here and the DiffTree's `za` mirror. Set per
-- buffer-in-window: the global default is `indent`, and the treesitter plugin
-- only stamps expr folding on whatever window is current when it configures
-- itself, so a patch window that came later can be left without it. 'foldlevel'
-- stays as-is (99 from lua/init/options.lua), so nothing starts folded.
if vim.wo[0][0].foldmethod ~= 'expr' then
  vim.wo[0][0].foldmethod = 'expr'
  vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
end

-- `ga` stages the file section (`block`) the cursor sits in, running the same
-- flow as the global `ga` (after/plugin/git.lua) on that path: `Git add -p`
-- for unstaged changes, plain `git add` for an untracked file. The patch text
-- names the file, so no buffer for it has to exist.
vim.keymap.set('n', 'ga', function()
  local path = lib.Diff.cursor_block_path(0)
  if not path then
    Snacks.notify.warn('no file section under the cursor', { title = 'Git', icon = '', style = 'fancy' })
    return
  end
  lib.git.add(path)
end, { buffer = 0, desc = 'git: git add -p file under cursor' })

-- `gf` opens the file of the section under the cursor in the **first tab**
-- (the working tab, marked with the code icon in the tabline), at the line the
-- patch points at: a hunk body line maps through the `@@` header onto the new
-- side, anywhere else in a section lands on line 1 (lib.Diff.file_location).
-- Native `gf` is useless here — `<cfile>` on a `+++ b/x` line reads `b/x` —
-- and the whole point of `:Diff`'s own tab is not to open code inside it,
-- which is why `git` is no longer in `config.filetypes.gf_open_in_top_split`.
vim.keymap.set('n', 'gf', function()
  lib.Diff.open_cursor_file()
end, { buffer = 0, desc = 'diff: open the file under the cursor in the first tab' })

-- Left-side tree of the file/hunk sections (lib.Diff.open_tree). `s` is the
-- quick toggle — buffer-local, so it shadows flash.nvim's jump only inside
-- patch buffers (`S`, `f`/`t` are untouched), and normal-mode `s` has nothing
-- to substitute in a `buftype=nowrite` buffer anyway. The tree buffer binds
-- the same key to close, so one key toggles the sidebar from either side.
vim.keymap.set('n', 'glt', function()
  lib.Diff.open_tree()
end, { buffer = 0, desc = 'diff: toggle file/hunk tree' })
vim.keymap.set('n', 's', function()
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

  local pending = false
  local function replan()
    if pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      if vim.api.nvim_buf_is_valid(bufnr) then
        lib.diff_filepath.render(bufnr)
      end
    end)
  end

  replan()
  vim.api.nvim_buf_attach(bufnr, false, { on_lines = replan })
end
