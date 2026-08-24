-- Integration test (real nvim, headless): the :DiffTree sidebar
-- (lib.Diff.open_tree / tree_rows / tree_hl_range / tree_row_containing).
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).
--
-- Note: `CursorMoved` never fires under --headless (no UI), so the hover and
-- bidirectional-sync autocmds are exercised through their pure helpers
-- (tree_hl_range / tree_row_containing) instead of by feeding cursor moves.

local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
vim.opt.rtp:append(cwd .. '/after')
package.path = cwd .. '/lua/?.lua;' .. package.path

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

local function assert_true(cond, msg)
  if not cond then
    error(msg or 'assert_true failed')
  end
end

-- The alias from after/plugin/autocmds.lua, mirrored here (under -u NONE
-- nothing sources the live config). Must precede setting filetype=git.
vim.treesitter.language.register('diff', 'git')
_G.lib = require('lib')

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'diff --git a/foo.txt b/foo.txt', -- 1  block 1
  'index 1111111..2222222 100644', -- 2
  '--- a/foo.txt', -- 3
  '+++ b/foo.txt', -- 4
  '@@ -1,2 +1,2 @@', -- 5  hunk 1
  '-old', -- 6
  '+new', -- 7
  ' context', -- 8
  '@@ -5,1 +5,1 @@ function bar()', -- 9  hunk 2
  '-x', -- 10
  '+y', -- 11
  'diff --git a/b.txt b/b.txt', -- 12 block 2
  'index 3333333..4444444 100644', -- 13
  '--- a/b.txt', -- 14
  '+++ b/b.txt', -- 15
  '@@ -1 +1 @@', -- 16 hunk 3
  '-a', -- 17
  '+b', -- 18
})
vim.bo[buf].filetype = 'git'
vim.api.nvim_win_set_buf(0, buf)

-- Wait for the parser to become available / parse successfully.
local parsed = false
for _ = 1, 100 do
  local ok = pcall(function()
    return vim.treesitter.get_parser(buf):parse()[1]
  end)
  if ok then
    parsed = true
    break
  end
  vim.wait(50)
end
assert_true(parsed, 'diff parser parsed buffer')

local Diff = require('lib.Diff')

-- ------------------------------------------------------------------
-- tree_rows: blocks + nested hunks in document order.
-- ------------------------------------------------------------------
local rows = Diff.tree_rows(buf)
assert_eq(#rows, 5, 'two blocks, three hunks')
assert_eq(rows[1].kind, 'block', 'row 1 is a block')
assert_eq(rows[1].lnum, 1, 'block 1 lnum')
assert_eq(rows[1].path, 'foo.txt', 'block 1 path (b/ prefix stripped)')
assert_eq(rows[1].summary, ' +2 -2', 'block 1 summary')
assert_eq(rows[2].kind, 'hunk', 'row 2 is a hunk')
assert_eq(rows[2].lnum, 5, 'hunk 1 lnum')
assert_eq(rows[2].text, '@@ -1,2 +1,2 @@', 'hunk 1 @@ line')
assert_eq(rows[3].lnum, 9, 'hunk 2 lnum')
assert_eq(rows[3].text, '@@ -5,1 +5,1 @@ function bar()', 'hunk 2 @@ line keeps the heading')
assert_eq(rows[4].kind, 'block', 'row 4 is a block')
assert_eq(rows[4].lnum, 12, 'block 2 lnum')
assert_eq(rows[4].path, 'b.txt', 'block 2 path')
assert_eq(rows[4].summary, ' +1 -1', 'block 2 summary')
assert_eq(rows[5].kind, 'hunk', 'row 5 is a hunk')
assert_eq(rows[5].lnum, 16, 'hunk 3 lnum')
assert_eq(rows[5].text, '@@ -1 +1 @@', 'hunk 3 @@ line')
-- ranges: block 1 spans rows 0..11, hunk 1 rows 4..8 (0-based).
assert_eq(rows[1].range[1], 0, 'block 1 range start')
assert_eq(rows[1].range[3], 11, 'block 1 range end')
assert_eq(rows[2].range[1], 4, 'hunk 1 range start')
assert_eq(rows[2].range[3], 8, 'hunk 1 range end')

-- ------------------------------------------------------------------
-- Pure helpers backing the hover and bidirectional-sync autocmds.
-- ------------------------------------------------------------------
assert_eq(Diff.tree_row_containing(rows, 0), 1, 'block header -> block row')
assert_eq(Diff.tree_row_containing(rows, 6), 2, 'inside hunk 1 -> hunk row')
assert_eq(Diff.tree_row_containing(rows, 16), 5, 'inside hunk 3 -> hunk row')
assert_eq(Diff.tree_row_containing(rows, 11), 4, 'block 2 header -> block row')
assert_eq(Diff.tree_row_containing(rows, 100), nil, 'past the end -> no row')

assert_eq({ Diff.tree_hl_range(buf, rows[1]) }, { 0, 0, 30 }, 'block highlight = header line')
assert_eq({ Diff.tree_hl_range(buf, rows[2]) }, { 4, 8, 0 }, 'hunk highlight = full hunk range')

-- ------------------------------------------------------------------
-- open_tree: left split, rendered lines, fold options, initial highlight.
-- ------------------------------------------------------------------
vim.api.nvim_win_set_cursor(0, { 18, 0 }) -- park source cursor away from row 1
local src_win = vim.api.nvim_get_current_win()
Diff.open_tree()
local tree_win = vim.api.nvim_get_current_win()
local tree_buf = vim.api.nvim_win_get_buf(tree_win)
assert_true(tree_win ~= src_win, 'tree opened in a new window')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 2, 'two windows in the tab')
assert_eq(vim.api.nvim_win_get_position(tree_win)[2], 0, 'tree window is on the left')
assert_eq(vim.bo[tree_buf].filetype, 'diff-tree', 'tree buffer filetype')
assert_eq(vim.wo[tree_win].foldmethod, 'expr', 'tree folds with expr')
assert_eq(vim.wo[tree_win].foldexpr, 'v:lua.lib.Diff.tree_foldexpr()', 'tree foldexpr wired')

-- No mini.icons under -u NONE: labels are bare paths, padded so summaries
-- align (widest label 'foo.txt' = 7).
assert_eq(vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false), {
  'foo.txt  +2 -2',
  '  @@ -1,2 +1,2 @@',
  '  @@ -5,1 +5,1 @@ function bar()',
  'b.txt    +1 -1',
  '  @@ -1 +1 @@',
}, 'tree renders block/hunk rows')

-- open_tree focused the first row: its header line is highlighted.
local ns = vim.api.nvim_get_namespaces()['lib.diff.tree']
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
assert_eq(#marks, 1, 'opening highlights the first block')
assert_eq(marks[1][2], 0, 'highlight starts on the diff --git line (0-based)')
assert_eq(marks[1][3], 0, 'highlight starts at col 0')

-- ------------------------------------------------------------------
-- <CR> jumps the source cursor to the row's lnum (keymaps do fire headless).
-- ------------------------------------------------------------------
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- hunk 1
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'x', false)
vim.wait(100)
assert_eq(vim.api.nvim_get_current_win(), src_win, 'jump focuses the source window')
assert_eq(vim.fn.line('.'), 5, '<CR> on hunk 1 jumps to its @@ line')

-- ------------------------------------------------------------------
-- Toggle: a second open_tree() closes the tree window.
-- ------------------------------------------------------------------
Diff.open_tree()
vim.wait(50)
assert_true(not vim.api.nvim_win_is_valid(tree_win), 'second DiffTree closes the tree')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'back to a single window')

print('OK: DiffTree sidebar')
vim.cmd('qa!')
