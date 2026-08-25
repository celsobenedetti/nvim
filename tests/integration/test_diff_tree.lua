-- Integration test (real nvim, headless): the :DiffTree sidebar
-- (lib.Diff.open_tree / tree_rows / tree_focus / tree_row_containing).
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).
--
-- Note: `CursorMoved` never fires under --headless (no UI), so the hover and
-- bidirectional-sync autocmds are exercised by calling tree_focus /
-- tree_row_containing directly instead of by feeding cursor moves.

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
-- tree_rows: a directory group header, its files, their hunks. Both files
-- here live at the repo root, so they share one `./` group.
-- ------------------------------------------------------------------
local rows = Diff.tree_rows(buf)
assert_eq(#rows, 6, 'one dir group, two blocks, three hunks')
assert_eq(rows[1].kind, 'dir', 'row 1 is the group header')
assert_eq(rows[1].dir, './', 'repo-root files group under ./')
assert_eq(rows[1].lnum, 1, "the group's jump target is its first file")
assert_eq(rows[1].blocks, { 1, 12 }, 'the group carries every file header (fold forwarding)')
assert_eq(rows[2].kind, 'block', 'row 2 is a block')
assert_eq(rows[2].lnum, 1, 'block 1 lnum')
assert_eq(rows[2].path, 'foo.txt', 'block 1 path (b/ prefix stripped)')
assert_eq(rows[2].name, 'foo.txt', 'block 1 basename (what the row shows)')
assert_eq(rows[2].status, 'M', 'block 1 is a content change')
assert_eq(rows[2].summary, ' +2 -2', 'block 1 summary')
assert_eq(rows[3].kind, 'hunk', 'row 3 is a hunk')
assert_eq(rows[3].lnum, 5, 'hunk 1 lnum')
assert_eq(rows[3].text, '@@ -1,2 +1,2 @@', 'hunk 1 @@ line')
assert_eq(rows[3].path, 'foo.txt', 'hunk rows carry their block path (file actions)')
assert_eq(rows[4].lnum, 9, 'hunk 2 lnum')
assert_eq(rows[4].text, '@@ -5,1 +5,1 @@ function bar()', 'hunk 2 @@ line keeps the heading')
assert_eq(rows[5].kind, 'block', 'row 5 is a block')
assert_eq(rows[5].lnum, 12, 'block 2 lnum')
assert_eq(rows[5].path, 'b.txt', 'block 2 path')
assert_eq(rows[5].summary, ' +1 -1', 'block 2 summary')
assert_eq(rows[6].kind, 'hunk', 'row 6 is a hunk')
assert_eq(rows[6].lnum, 16, 'hunk 3 lnum')
assert_eq(rows[6].text, '@@ -1 +1 @@', 'hunk 3 @@ line')
assert_eq(rows[6].path, 'b.txt', 'hunk 3 path is block 2')
-- ranges: block 1 spans rows 0..11, hunk 1 rows 4..8 (0-based); the group
-- header borrows its first file's, so hover/`<CR>` land on that file.
assert_eq(rows[1].range, rows[2].range, "the group header borrows its first file's range")
assert_eq(rows[2].range[1], 0, 'block 1 range start')
assert_eq(rows[2].range[3], 11, 'block 1 range end')
assert_eq(rows[3].range[1], 4, 'hunk 1 range start')
assert_eq(rows[3].range[3], 8, 'hunk 1 range end')

-- ------------------------------------------------------------------
-- Pure helpers backing the hover and bidirectional-sync autocmds. Group
-- headers are skipped: their range is a copy of a file's, and it is the file
-- row the source cursor should sync to.
-- ------------------------------------------------------------------
assert_eq(Diff.tree_row_containing(rows, 0), 2, 'block header -> block row')
assert_eq(Diff.tree_row_containing(rows, 6), 3, 'inside hunk 1 -> hunk row')
assert_eq(Diff.tree_row_containing(rows, 16), 6, 'inside hunk 3 -> hunk row')
assert_eq(Diff.tree_row_containing(rows, 11), 5, 'block 2 header -> block row')
assert_eq(Diff.tree_row_containing(rows, 100), nil, 'past the end -> no row')

-- ------------------------------------------------------------------
-- open_tree: left split, rendered lines, fold options, initial focus.
-- ------------------------------------------------------------------
-- A window shorter than the 18-line diff, so 'topline' can actually move, and
-- a non-zero 'scrolloff' to prove hover's `zt` respects it.
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
assert_eq(vim.api.nvim_win_get_width(tree_win), 30, 'the first open uses the default width')
assert_eq({ vim.wo[tree_win].number, vim.wo[tree_win].relativenumber }, { false, false }, 'no number column')
assert_eq(vim.wo[tree_win].foldmethod, 'expr', 'tree folds with expr')
assert_eq(vim.wo[tree_win].foldexpr, 'v:lua.lib.Diff.tree_foldexpr()', 'tree foldexpr wired')
-- The rows must be stored before 'foldmethod' is set: that assignment
-- evaluates the foldexpr immediately, and with `diff_tree_rows` still unset
-- every line cached level 0 (nothing edits this buffer to invalidate it).
assert_eq(
  vim.api.nvim_win_call(tree_win, function()
    return { vim.fn.foldlevel(1), vim.fn.foldlevel(2), vim.fn.foldlevel(3) }
  end),
  { 1, 2, 2 },
  'dir fold (level 1) holds the file folds (level 2) holding the hunk rows'
)

-- No mini.icons under -u NONE, so no glyph column: ` <status> <basename>`,
-- with the summary three spaces behind the name.
assert_eq(vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false), {
  ' ./',
  ' M foo.txt   +2 -2',
  '   @@ -1,2 +1,2 @@',
  '   @@ -5,1 +5,1 @@ function bar()',
  ' M b.txt   +1 -1',
  '   @@ -1 +1 @@',
}, 'tree renders dir/block/hunk rows')

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

-- Row colours: the group header as a Directory, each status letter in a diff
-- group, hunk rows dimmed as Comment (no icon marks without mini.icons).
local tree_ns = vim.api.nvim_get_namespaces()['lib.diff.tree']
local tree_marks = vim.api.nvim_buf_get_extmarks(tree_buf, tree_ns, 0, -1, { details = true })
assert_eq(#tree_marks, 6, 'one dir mark, two status letters, three hunk rows')
assert_eq({ tree_marks[1][2], tree_marks[1][3] }, { 0, 0 }, 'the dir mark spans its whole line')
assert_eq(tree_marks[1][4].hl_group, 'Directory', 'group headers use Directory')
assert_eq({ tree_marks[2][2], tree_marks[2][3] }, { 1, 1 }, "block 1's status letter, column 2")
assert_eq({ tree_marks[2][4].end_col, tree_marks[2][4].hl_group }, { 2, 'Changed' }, 'M is a Changed letter')
assert_eq({ tree_marks[3][2], tree_marks[3][3] }, { 2, 0 }, 'first hunk mark on tree line 3')
assert_eq(tree_marks[3][4].hl_group, 'Comment', 'hunk rows use Comment')
assert_eq({ tree_marks[6][2], tree_marks[6][3] }, { 5, 0 }, 'last mark on tree line 6')

-- Moving to a hunk row restores the bar's normal palette and highlights that
-- hunk's `@@` header line instead — the `location` node's exact span, in the
-- `lib.diff.tree.hover` namespace (driven via M.tree_focus; CursorMoved never
-- fires under --headless, so the autocmd wiring is covered by the keymap
-- test).
vim.api.nvim_win_set_cursor(tree_win, { 3, 0 }) -- hunk 1
Diff.tree_focus(tree_buf, tree_win)
assert_eq(require('lib.diff_filepath').hover(buf), nil, 'hunk hover clears the bar hover')
bars = vim.api.nvim_buf_get_extmarks(buf, bar_ns, 0, -1, { details = true })
assert_eq(bars[1][4].hl_group, 'DiffFileBar', 'bar range back to normal palette')
assert_eq(bars[1][4].virt_text[1][2], 'DiffFileBarPath', 'bar chunks back to normal palette')
assert_eq(vim.api.nvim_buf_get_extmarks(buf, tree_ns, 0, -1, {}), {}, 'and paints nothing in TREE_NS')

local hover_ns = vim.api.nvim_get_namespaces()['lib.diff.tree.hover']
local function hunk_hl()
  local marks = vim.api.nvim_buf_get_extmarks(buf, hover_ns, 0, -1, { details = true })
  if #marks == 0 then
    return nil
  end
  return { marks[1][2], marks[1][3], marks[1][4].end_row, marks[1][4].end_col, marks[1][4].hl_group }
end
-- `@@ -1,2 +1,2 @@` on line 5: row 4, columns 0..15.
assert_eq(hunk_hl(), { 4, 0, 4, 15, 'DiffHunkHover' }, 'hunk hover marks its @@ header')

-- Hunk 2's header carries git's function heading, and the `location` node
-- covers it, so the highlight runs to the end of the line.
vim.api.nvim_win_set_cursor(tree_win, { 4, 0 }) -- hunk 2
Diff.tree_focus(tree_buf, tree_win)
assert_eq(hunk_hl(), { 8, 0, 8, 30, 'DiffHunkHover' }, 'the heading is part of the @@ node')

-- One mark at a time, and none at all on a file or group row.
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- block foo.txt
Diff.tree_focus(tree_buf, tree_win)
assert_eq(hunk_hl(), nil, 'a file row clears the hunk highlight')
vim.api.nvim_win_set_cursor(tree_win, { 1, 0 }) -- the ./ group
Diff.tree_focus(tree_buf, tree_win)
assert_eq(hunk_hl(), nil, 'a group row paints none either')

-- ------------------------------------------------------------------
-- Hover parks the section at the top of the diff window (`zt`), 'scrolloff'
-- lines of context above it.
-- ------------------------------------------------------------------
assert_eq(vim.wo[src_win].scrolloff, 4, 'the diff window keeps its scrolloff')

local function src_topline()
  return vim.api.nvim_win_call(src_win, function()
    return vim.fn.line('w0')
  end)
end

vim.api.nvim_win_set_cursor(tree_win, { 5, 0 }) -- block 2, source line 12
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 8, 'hovering block 2 tops its header, minus the scrolloff margin')
-- The cursor comes along: nvim keeps a window's cursor visible, so a topline
-- that would scroll it away is undone (setting topline alone did nothing).
assert_eq(vim.api.nvim_win_get_cursor(src_win)[1], 12, 'source cursor follows the hover')
assert_eq(vim.api.nvim_get_current_win(), tree_win, 'focus stays in the tree')

vim.api.nvim_win_set_cursor(tree_win, { 6, 0 }) -- hunk 3, source line 16
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 12, 'hovering hunk 3 tops its @@ line, minus the margin')

vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- back to block 1, line 1
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 1, 'hovering block 1 scrolls back to the top (no margin to keep)')

-- A group header previews its first file, so hovering `./` is hovering
-- foo.txt: same scroll, and the bar lights up on the Hover palette.
vim.api.nvim_win_set_cursor(tree_win, { 5, 0 })
Diff.tree_focus(tree_buf, tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 1, 0 }) -- the ./ header
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 1, "hovering a group tops its first file's header")
assert_eq(vim.api.nvim_win_get_cursor(src_win)[1], 1, 'and moves the source cursor there')
assert_eq(require('lib.diff_filepath').hover(buf), 0, "the group hover lights that file's bar")

-- ------------------------------------------------------------------
-- J / K scroll the diff window from the tree, focus staying put.
-- ------------------------------------------------------------------
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(50)
end

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- block 1, source line 1
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_topline(), 1, 'starting at the top of the patch')
feed('J')
assert_eq(src_topline(), 2, 'J scrolls the diff one line down')
assert_eq(vim.api.nvim_get_current_win(), tree_win, 'focus stays in the tree')
assert_eq(vim.api.nvim_win_get_cursor(tree_win)[1], 2, 'and the tree cursor stays on its row')
feed('3J')
assert_eq(src_topline(), 5, 'a count scrolls that many lines (3J)')
feed('K')
assert_eq(src_topline(), 4, 'K scrolls back up')
feed('2K')
assert_eq(src_topline(), 2, 'with a count too (2K)')
feed('9K')
assert_eq(src_topline(), 1, 'and stops at the first line')

-- The source->tree sync only follows a cursor the user moved *in the diff
-- window*: a J/K scroll drags that cursor along ('scrolloff' pushes it), and
-- syncing the tree onto it would hover that row and scroll right back.
-- CursorMoved never fires under --headless, so both halves are driven with
-- nvim_exec_autocmds.
vim.api.nvim_win_set_cursor(src_win, { 16, 0 }) -- inside hunk 3 = tree row 6
vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
assert_eq(vim.api.nvim_win_get_cursor(tree_win)[1], 2, 'a move while the tree is focused is ignored')
vim.api.nvim_set_current_win(src_win)
vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
assert_eq(vim.api.nvim_win_get_cursor(tree_win)[1], 6, 'from the diff window it syncs the tree')
vim.api.nvim_set_current_win(tree_win)

-- ------------------------------------------------------------------
-- <CR> jumps the source cursor to the row's lnum (keymaps do fire headless).
-- ------------------------------------------------------------------
vim.api.nvim_win_set_cursor(tree_win, { 3, 0 }) -- hunk 1
Diff.tree_focus(tree_buf, tree_win) -- as hovering it would
assert_true(hunk_hl() ~= nil, 'the hunk header is highlighted while hovered')
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'x', false)
vim.wait(100)
assert_eq(vim.api.nvim_get_current_win(), src_win, 'jump focuses the source window')
assert_eq(vim.fn.line('.'), 5, '<CR> on hunk 1 jumps to its @@ line')
-- Leaving the tree drops the hover marks (BufLeave; it fires headless, unlike
-- CursorMoved).
assert_eq(hunk_hl(), nil, 'leaving the tree clears the hunk highlight')
assert_eq(require('lib.diff_filepath').hover(buf), nil, 'and the bar hover')

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

-- Hover leaves the fold state alone: it scrolls the section to the top and
-- nothing more, so a closed section stays closed until `zo`/`zO` opens it.
vim.api.nvim_set_current_win(tree_win)
vim.wo[src_win].foldlevel = 0 -- everything closed
assert_eq(src_foldclosed(1), 1, 'block 1 starts closed')
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- block foo.txt
Diff.tree_focus(tree_buf, tree_win)
assert_eq(src_foldclosed(1), 1, 'hover does not open the hovered block')
assert_eq(src_foldclosed(5), 1, 'nor the hunk folds inside it')
assert_eq(src_foldclosed(12), 12, 'nor anything else')
assert_eq(vim.api.nvim_win_get_cursor(src_win)[1], 1, 'it still moves the source cursor there')
vim.wo[src_win].foldlevel = 99 -- back to all-open for the fold-command tests

assert_eq(src_foldclosed(1), -1, 'source starts unfolded')

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 }) -- block foo.txt
feed('za')
assert_eq(src_foldclosed(1), 1, 'za on a file row closes its block in the diff')
assert_eq(tree_foldclosed(2), 2, 'and mirrors onto the tree row (hides its hunks)')
assert_eq(vim.api.nvim_get_current_win(), tree_win, 'focus stays in the tree')

feed('za')
assert_eq(src_foldclosed(1), -1, 'za again reopens the block')
assert_eq(tree_foldclosed(2), -1, 'tree fold reopens too')

vim.api.nvim_win_set_cursor(tree_win, { 3, 0 }) -- hunk 1
feed('za')
assert_eq(src_foldclosed(5), 5, 'za on a hunk row closes that hunk')
assert_eq(src_foldclosed(1), -1, 'the enclosing block stays open')
assert_eq(tree_foldclosed(3), -1, 'hunk rows have no tree fold to mirror')
feed('za')
assert_eq(src_foldclosed(5), -1, 'za reopens the hunk')

-- A group header folds every file in it (it owns no fold in the diff itself),
-- and its own tree fold hides the whole subtree.
vim.api.nvim_win_set_cursor(tree_win, { 1, 0 }) -- the ./ header
feed('za')
assert_eq({ src_foldclosed(1), src_foldclosed(12) }, { 1, 12 }, 'za on a group closes all of its files')
assert_eq(tree_foldclosed(1), 1, 'and closes the tree group (hides its files and hunks)')
feed('za')
assert_eq({ src_foldclosed(1), src_foldclosed(12) }, { -1, -1 }, 'za reopens all of them')
assert_eq(tree_foldclosed(1), -1, 'the tree group reopens too')

feed('zc')
assert_eq({ src_foldclosed(12), tree_foldclosed(1) }, { 12, 1 }, 'zc on a group closes it')
feed('zo')
assert_eq({ src_foldclosed(12), tree_foldclosed(1) }, { -1, -1 }, 'zo on a group reopens it')

-- `zc` / `zo`: single level, and idempotent on a repeated press.
vim.api.nvim_win_set_cursor(tree_win, { 2, 0 })
feed('zc')
assert_eq({ src_foldclosed(1), tree_foldclosed(2) }, { 1, 2 }, 'zc closes the block (and the tree row)')
feed('zc')
assert_eq(src_foldclosed(1), 1, 'zc again is a no-op')
feed('zo')
assert_eq({ src_foldclosed(1), tree_foldclosed(2) }, { -1, -1 }, 'zo reopens both')
feed('zo')
assert_eq(src_foldclosed(1), -1, 'zo again is a no-op')

-- On a hunk row, `zc` closes just that hunk; `zC` recurses out to the block
-- (fold commands act on the folds containing the cursor line).
vim.api.nvim_win_set_cursor(tree_win, { 3, 0 })
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
assert_eq(tree_foldclosed(1), 1, 'and collapses the tree to one row per directory')

feed('zr')
assert_eq(vim.wo[src_win].foldlevel, 1, 'zr lifts the diff foldlevel by one')
assert_eq({ src_foldclosed(1), src_foldclosed(5) }, { -1, 5 }, 'blocks open, hunks still folded')
assert_eq({ tree_foldclosed(1), tree_foldclosed(2) }, { -1, 2 }, 'the tree shows its files, hunks folded')

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
vim.api.nvim_win_set_cursor(tree_win, { 3, 0 }) -- hunk 1, under foo.txt
feed('ga')
assert_eq(staged, { 'foo.txt' }, 'ga on a hunk row stages its block file')
assert_eq(vim.api.nvim_get_current_win(), src_win, 'ga focuses the diff window for the add -p split')

vim.api.nvim_set_current_win(tree_win)
vim.api.nvim_win_set_cursor(tree_win, { 5, 0 }) -- block b.txt
feed('ga')
assert_eq(staged, { 'foo.txt', 'b.txt' }, 'ga on a file row stages that file')

git.add = real_add

-- ------------------------------------------------------------------
-- Toggle: a second open_tree() closes the tree window, and the next open
-- restores the width it had (kept as a share of 'columns', see tree_width).
-- ------------------------------------------------------------------
vim.api.nvim_win_set_width(tree_win, 40) -- as a <C-w>> resize would
vim.api.nvim_set_current_win(src_win)
Diff.open_tree()
vim.wait(50)
assert_true(not vim.api.nvim_win_is_valid(tree_win), 'second DiffTree closes the tree')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'back to a single window')

Diff.open_tree()
local tree_win2 = vim.api.nvim_get_current_win()
assert_eq(vim.api.nvim_win_get_width(tree_win2), 40, 'reopening restores the sidebar width')
-- Rows are re-rendered for the new width. A short label reads the same either
-- way (its summary sits three spaces behind the name); the width only decides
-- how much room a long name gets before it is truncated.
assert_eq(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1], ' M foo.txt   +2 -2', 'rows re-rendered')

-- `s` closes the tree, the same toggle the diff buffer binds it to
-- (after/ftplugin/git.lua, which -u NONE does not source here).
feed('s')
assert_true(not vim.api.nvim_win_is_valid(tree_win2), 's closes the tree')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'back to a single window again')
assert_eq(vim.wo[src_win].scrolloff, 4, 'the diff window scrolloff was never touched')

-- ------------------------------------------------------------------
-- Directory grouping: a second patch whose files spread over several
-- directories, with `lua/lib/` interrupted by `lua/config.lua` (git's path
-- sort does that whenever a sibling directory sorts inside the range) and one
-- file of every status.
-- ------------------------------------------------------------------
local buf2 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf2, 0, -1, false, {
  'diff --git a/AGENTS.md b/AGENTS.md', -- 1  root file
  'index 1111111..2222222 100644', -- 2
  '--- a/AGENTS.md', -- 3
  '+++ b/AGENTS.md', -- 4
  '@@ -1 +1,2 @@', -- 5
  ' x', -- 6
  '+y', -- 7
  'diff --git a/lua/lib/a.lua b/lua/lib/a.lua', -- 8  lua/lib/
  'index 1111111..2222222 100644', -- 9
  '--- a/lua/lib/a.lua', -- 10
  '+++ b/lua/lib/a.lua', -- 11
  '@@ -1 +1 @@', -- 12
  '-a', -- 13
  '+A', -- 14
  'diff --git a/lua/config.lua b/lua/config.lua', -- 15 lua/ (added)
  'new file mode 100644', -- 16
  'index 0000000..1111111', -- 17
  '--- /dev/null', -- 18
  '+++ b/lua/config.lua', -- 19
  '@@ -0,0 +1 @@', -- 20
  '+cfg', -- 21
  'diff --git a/lua/lib/a-very-long-module-name.lua b/lua/lib/a-very-long-module-name.lua', -- 22 lua/lib/ again (deleted)
  'deleted file mode 100644', -- 23
  'index 1111111..0000000', -- 24
  '--- a/lua/lib/a-very-long-module-name.lua', -- 25
  '+++ /dev/null', -- 26
  '@@ -1 +0,0 @@', -- 27
  '-gone', -- 28
  'diff --git a/old/x.txt b/new/x.txt', -- 29 new/ (renamed, no hunks)
  'similarity index 100%', -- 30
  'rename from old/x.txt', -- 31
  'rename to new/x.txt', -- 32
})
vim.bo[buf2].filetype = 'git'
vim.api.nvim_win_set_buf(0, buf2)

local rows2 = Diff.tree_rows(buf2)
local shape = {}
for _, r in ipairs(rows2) do
  shape[#shape + 1] = r.kind == 'dir' and r.dir or (r.kind == 'block' and (r.status .. ' ' .. r.name) or r.text)
end
assert_eq(shape, {
  './',
  'M AGENTS.md',
  '@@ -1 +1,2 @@',
  'lua/lib/',
  'M a.lua',
  '@@ -1 +1 @@',
  'D a-very-long-module-name.lua',
  '@@ -1 +0,0 @@',
  'lua/',
  'A config.lua',
  '@@ -0,0 +1 @@',
  'new/',
  'R x.txt',
}, 'files are grouped under their directory, in first-appearance order')
-- The deleted file sits with a.lua, four sections further down the patch: the
-- grouping is by directory, not by consecutive runs.
assert_eq(rows2[7].lnum, 22, 'the pulled-up file keeps its own jump target')
assert_eq(rows2[4].blocks, { 8, 22 }, 'the group header carries both of its files')
assert_eq(rows2[4].lnum, 8, 'and jumps to the first of them')
assert_eq(rows2[13].summary, '', 'a rename has no +/- lines to summarise')
assert_eq(rows2[13].path, 'new/x.txt', 'a rename is filed under its new path')

local src_win2 = vim.api.nvim_get_current_win()
Diff.open_tree()
local tree2 = vim.api.nvim_get_current_win()
local tree_buf2 = vim.api.nvim_win_get_buf(tree2)
-- The group header one space in (column 0 is the viewed gutter), its files
-- indented behind a status letter and
-- carrying the basename only, each summary three spaces behind its name, and a
-- name too long for the room left over cut with an ellipsis.
assert_eq(vim.api.nvim_buf_get_lines(tree_buf2, 0, -1, false), {
  ' ./',
  ' M AGENTS.md   +1',
  '   @@ -1 +1,2 @@',
  ' lua/lib/',
  ' M a.lua   +1 -1',
  '   @@ -1 +1 @@',
  ' D a-very-long-module-n…   -1',
  '   @@ -1 +0,0 @@',
  ' lua/',
  ' A config.lua   +1',
  '   @@ -0,0 +1 @@',
  ' new/',
  ' R x.txt',
}, 'grouped tree rendering')

-- Fold levels: dir 1, file 2 (a file without hunks is just a line in its
-- group), hunk 2.
assert_eq(
  vim.api.nvim_win_call(tree2, function()
    local lv = {}
    for _, l in ipairs({ 1, 2, 3, 4, 5, 9, 12, 13 }) do
      lv[#lv + 1] = vim.fn.foldlevel(l)
    end
    return lv
  end),
  { 1, 2, 2, 1, 2, 1, 1, 1 },
  'dir/file/hunk fold levels'
)
-- Toggle off from the diff window (open_tree acts on the current buffer, and
-- the tree buffer is not a patch).
vim.api.nvim_set_current_win(src_win2)
Diff.open_tree()
assert_true(not vim.api.nvim_win_is_valid(tree2), 'the grouped tree closes again')

print('OK: DiffTree sidebar')
vim.cmd('qa!')
