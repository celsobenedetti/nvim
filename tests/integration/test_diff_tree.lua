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
assert_eq(rows[2].path, 'foo.txt', 'hunk rows carry their block path (file actions)')
assert_eq(rows[3].lnum, 9, 'hunk 2 lnum')
assert_eq(rows[3].text, '@@ -5,1 +5,1 @@ function bar()', 'hunk 2 @@ line keeps the heading')
assert_eq(rows[4].kind, 'block', 'row 4 is a block')
assert_eq(rows[4].lnum, 12, 'block 2 lnum')
assert_eq(rows[4].path, 'b.txt', 'block 2 path')
assert_eq(rows[4].summary, ' +1 -1', 'block 2 summary')
assert_eq(rows[5].kind, 'hunk', 'row 5 is a hunk')
assert_eq(rows[5].lnum, 16, 'hunk 3 lnum')
assert_eq(rows[5].text, '@@ -1 +1 @@', 'hunk 3 @@ line')
assert_eq(rows[5].path, 'b.txt', 'hunk 3 path is block 2')
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
-- A window shorter than the 18-line diff, so 'topline' can actually move, and
-- a non-zero 'scrolloff' to prove the tree zeroes and restores it.
vim.o.lines = 12
vim.o.scrolloff = 4

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
-- The rows must be stored before 'foldmethod' is set: that assignment
-- evaluates the foldexpr immediately, and with `diff_tree_rows` still unset
-- every line cached level 0 (nothing edits this buffer to invalidate it).
assert_eq(
  vim.api.nvim_win_call(tree_win, function()
    return { vim.fn.foldlevel(1), vim.fn.foldlevel(2) }
  end),
  { 1, 1 },
  'block row opens a fold its hunk rows sit in'
)

-- No mini.icons under -u NONE: labels are bare paths, padded so summaries
-- align (widest label 'foo.txt' = 7).
assert_eq(vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false), {
  'foo.txt  +2 -2',
  '  @@ -1,2 +1,2 @@',
  '  @@ -5,1 +5,1 @@ function bar()',
  'b.txt    +1 -1',
  '  @@ -1 +1 @@',
}, 'tree renders block/hunk rows')

-- open_tree focused the first row (a block): its filepath bar is re-emitted
-- on the Hover palette (lib.diff_filepath.set_hover), and no Visual mark is
-- painted — a second extmark can't restyle the bar's baked-in virt_text.
local bar_ns = vim.api.nvim_get_namespaces()['nvim.diff_filepath']
local bars = vim.api.nvim_buf_get_extmarks(buf, bar_ns, 0, -1, { details = true })
assert_eq(#bars, 2, 'one filepath bar per block')
assert_eq(bars[1][2], 0, 'first bar sits on the diff --git line (0-based)')
assert_eq(bars[1][4].hl_group, 'DiffFileBarHover', 'hovered bar range group')
assert_eq(bars[1][4].virt_text, {
  { 'foo.txt', 'DiffFileBarHoverPath' },
  { ' +2 -2', 'DiffFileBarHoverSummary' },
}, 'hovered bar chunks use the Hover palette')
assert_eq(require('lib.diff_filepath').hover(buf), 0, 'hover state records block 1 row')

-- Hunk rows in the tree buffer are dimmed as Comment.
local tree_ns = vim.api.nvim_get_namespaces()['lib.diff.tree']
local tree_marks = vim.api.nvim_buf_get_extmarks(tree_buf, tree_ns, 0, -1, { details = true })
assert_eq(#tree_marks, 3, 'three hunk rows carry Comment marks')
assert_eq({ tree_marks[1][2], tree_marks[1][3] }, { 1, 0 }, 'first mark on tree line 2')
assert_eq(tree_marks[1][4].hl_group, 'Comment', 'hunk rows use Comment')
assert_eq({ tree_marks[3][2], tree_marks[3][3] }, { 4, 0 }, 'last mark on tree line 5')

-- Moving to a hunk row restores the bar's normal palette and paints Visual
-- over the hunk instead (driven via M.tree_focus; CursorMoved never fires
-- under --headless, so the autocmd wiring is covered by the keymap test).
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 })
Diff.tree_focus(tree_buf, tree_win)
assert_eq(require('lib.diff_filepath').hover(buf), nil, 'hunk hover clears the bar hover')
bars = vim.api.nvim_buf_get_extmarks(buf, bar_ns, 0, -1, { details = true })
assert_eq(bars[1][4].hl_group, 'DiffFileBar', 'bar range back to normal palette')
assert_eq(bars[1][4].virt_text[1][2], 'DiffFileBarPath', 'bar chunks back to normal palette')
local src_marks = vim.api.nvim_buf_get_extmarks(buf, tree_ns, 0, -1, {})
assert_eq(#src_marks, 1, 'hunk hover paints the source range')
assert_eq(src_marks[1][2], 4, 'Visual starts on hunk 1 @@ line')

-- ------------------------------------------------------------------
-- Hover parks the section on the diff window's first line (`zt`).
-- ------------------------------------------------------------------
assert_eq(vim.wo[src_win].scrolloff, 0, 'tree zeroes the diff window scrolloff (exact zt)')

local function src_topline()
  return vim.api.nvim_win_call(src_win, function()
    return vim.fn.line('w0')
  end)
end

vim.api.nvim_win_set_cursor(tree_win, { 4, 0 }) -- block 2, source line 12
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 12, 'hovering block 2 puts its header on the first line')
-- The cursor comes along: nvim keeps a window's cursor visible, so a topline
-- that would scroll it away is undone (setting topline alone did nothing).
assert_eq(vim.api.nvim_win_get_cursor(src_win)[1], 12, 'source cursor follows the hover')
assert_eq(vim.api.nvim_get_current_win(), tree_win, 'focus stays in the tree')

vim.api.nvim_win_set_cursor(tree_win, { 5, 0 }) -- hunk 3, source line 16
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 16, 'hovering hunk 3 puts its @@ line on top')

vim.api.nvim_win_set_cursor(tree_win, { 1, 0 }) -- back to block 1, line 1
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 1, 'hovering block 1 scrolls back to the top')

-- ------------------------------------------------------------------
-- <CR> jumps the source cursor to the row's lnum (keymaps do fire headless).
-- ------------------------------------------------------------------
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- hunk 1
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'x', false)
vim.wait(100)
assert_eq(vim.api.nvim_get_current_win(), src_win, 'jump focuses the source window')
assert_eq(vim.fn.line('.'), 5, '<CR> on hunk 1 jumps to its @@ line')

-- ------------------------------------------------------------------
-- `za`: folds the section in the diff buffer, mirrored on the tree's own
-- fold for file rows.
-- ------------------------------------------------------------------
-- after/ftplugin/git.lua puts treesitter folds on patch windows; -u NONE
-- sources no ftplugin here, and the default 'foldlevel' is 0 (all closed), so
-- set the same state up by hand.
vim.wo[src_win].foldmethod = 'expr'
vim.wo[src_win].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo[src_win].foldlevel = 99
vim.wo[src_win].foldenable = true

local function src_foldclosed(lnum)
  return vim.api.nvim_win_call(src_win, function()
    return vim.fn.foldclosed(lnum)
  end)
end

local function tree_foldclosed(lnum)
  return vim.api.nvim_win_call(tree_win, function()
    return vim.fn.foldclosed(lnum)
  end)
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(50)
end

assert_eq(src_foldclosed(1), -1, 'source starts unfolded')

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 1, 0 }) -- block foo.txt
feed('za')
assert_eq(src_foldclosed(1), 1, 'za on a file row closes its block in the diff')
assert_eq(tree_foldclosed(1), 1, 'and mirrors onto the tree row (hides its hunks)')
assert_eq(vim.api.nvim_get_current_win(), tree_win, 'focus stays in the tree')

feed('za')
assert_eq(src_foldclosed(1), -1, 'za again reopens the block')
assert_eq(tree_foldclosed(1), -1, 'tree fold reopens too')

vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- hunk 1
feed('za')
assert_eq(src_foldclosed(5), 5, 'za on a hunk row closes that hunk')
assert_eq(src_foldclosed(1), -1, 'the enclosing block stays open')
assert_eq(tree_foldclosed(2), -1, 'hunk rows have no tree fold to mirror')
feed('za')
assert_eq(src_foldclosed(5), -1, 'za reopens the hunk')

-- `zc` / `zo`: single level, and idempotent on a repeated press.
vim.api.nvim_win_set_cursor(tree_win, { 1, 0 })
feed('zc')
assert_eq({ src_foldclosed(1), tree_foldclosed(1) }, { 1, 1 }, 'zc closes the block (and the tree row)')
feed('zc')
assert_eq(src_foldclosed(1), 1, 'zc again is a no-op')
feed('zo')
assert_eq({ src_foldclosed(1), tree_foldclosed(1) }, { -1, -1 }, 'zo reopens both')
feed('zo')
assert_eq(src_foldclosed(1), -1, 'zo again is a no-op')

-- On a hunk row, `zc` closes just that hunk; `zC` recurses out to the block
-- (fold commands act on the folds containing the cursor line).
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 })
feed('zc')
assert_eq({ src_foldclosed(5), src_foldclosed(1) }, { 5, -1 }, 'zc on a hunk row closes only the hunk')
feed('zo')
assert_eq(src_foldclosed(5), -1, 'zo reopens the hunk')
feed('zC')
assert_eq(src_foldclosed(1), 1, 'zC on a hunk row closes its block too (recursive)')
feed('zO')
assert_eq({ src_foldclosed(1), src_foldclosed(5) }, { -1, -1 }, 'zO reopens every level')

-- `zA` toggles recursively from the same row.
feed('zA')
assert_eq(src_foldclosed(1), 1, 'zA closes hunk + block')
feed('zA')
assert_eq({ src_foldclosed(1), src_foldclosed(5) }, { -1, -1 }, 'zA toggles all of it back open')

-- ------------------------------------------------------------------
-- Window-wide fold commands: forwarded verbatim, mirrored in the tree.
-- ------------------------------------------------------------------
feed('zM')
assert_eq({ src_foldclosed(1), src_foldclosed(12) }, { 1, 12 }, 'zM closes every block in the diff')
assert_eq(vim.wo[src_win].foldlevel, 0, 'zM zeroes the diff foldlevel')
assert_eq(tree_foldclosed(1), 1, 'and collapses the tree to one row per file')

feed('zr')
assert_eq(vim.wo[src_win].foldlevel, 1, 'zr lifts the diff foldlevel by one')
assert_eq({ src_foldclosed(1), src_foldclosed(5) }, { -1, 5 }, 'blocks open, hunks still folded')
assert_eq(tree_foldclosed(1), -1, 'the tree (one fold level) is fully expanded again')

feed('zM')
feed('2zr')
assert_eq(vim.wo[src_win].foldlevel, 2, 'counts are forwarded (2zr)')

feed('zR')
assert_eq({ src_foldclosed(1), src_foldclosed(5), tree_foldclosed(1) }, { -1, -1, -1 }, 'zR opens everything')

-- ------------------------------------------------------------------
-- `ga`: stages the row's file through lib.git (covered against a real repo
-- in tests/integration/test_diff_ga.lua; here just the hand-off).
-- ------------------------------------------------------------------
local git = require('lib.git')
local real_add = git.add
local staged = {}
git.add = function(file)
  staged[#staged + 1] = file
end

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- hunk 1, under foo.txt
feed('ga')
assert_eq(staged, { 'foo.txt' }, 'ga on a hunk row stages its block file')
assert_eq(vim.api.nvim_get_current_win(), src_win, 'ga focuses the diff window for the add -p split')

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 4, 0 }) -- block b.txt
feed('ga')
assert_eq(staged, { 'foo.txt', 'b.txt' }, 'ga on a file row stages that file')

git.add = real_add

-- ------------------------------------------------------------------
-- Toggle: a second open_tree() closes the tree window.
-- ------------------------------------------------------------------
Diff.open_tree()
vim.wait(50)
assert_true(not vim.api.nvim_win_is_valid(tree_win), 'second DiffTree closes the tree')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'back to a single window')
assert_eq(vim.wo[src_win].scrolloff, 4, 'closing restores the diff window scrolloff')

print('OK: DiffTree sidebar')
vim.cmd('qa!')
