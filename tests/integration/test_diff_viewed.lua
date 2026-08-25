-- Integration test (real nvim, headless): the DiffTree "viewed" marks —
-- `<space>` / lib.Diff.tree_toggle_viewed. Covers the propagation between a
-- file and its hunks (and a directory and its files), the extmark the mark
-- paints, the fold a viewed file collapses into on both sides, and that the
-- flags survive closing and reopening the sidebar.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

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

-- The alias from after/plugin/autocmds.lua (-u NONE sources no config).
vim.treesitter.language.register('diff', 'git')
_G.lib = require('lib')
local Diff = require('lib.Diff')

-- Two files in two directories: `lua/a.lua` with two hunks, `b.txt` with one.
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'diff --git a/lua/a.lua b/lua/a.lua', -- 1  block 1
  'index 1111111..2222222 100644', --      2
  '--- a/lua/a.lua', --                    3
  '+++ b/lua/a.lua', --                    4
  '@@ -1,2 +1,2 @@', --                    5  hunk 1
  '-old', --                               6
  '+new', --                               7
  ' context', --                           8
  '@@ -5,1 +5,1 @@ function bar()', --     9  hunk 2
  '-x', --                                10
  '+y', --                                11
  'diff --git a/b.txt b/b.txt', --        12  block 2
  'index 3333333..4444444 100644', --     13
  '--- a/b.txt', --                       14
  '+++ b/b.txt', --                       15
  '@@ -1 +1 @@', --                       16  hunk 3
  '-a', --                                17
  '+b', --                                18
})
vim.bo[buf].filetype = 'git'
vim.api.nvim_win_set_buf(0, buf)

local parsed = false
for _ = 1, 100 do
  if pcall(function()
    return vim.treesitter.get_parser(buf):parse()[1]
  end) then
    parsed = true
    break
  end
  vim.wait(50)
end
assert_true(parsed, 'diff parser parsed buffer')

vim.o.lines = 20
local src_win = vim.api.nvim_get_current_win()
Diff.open_tree()
local tree_win = vim.api.nvim_get_current_win()
local tree_buf = vim.api.nvim_win_get_buf(tree_win)

-- Row layout (both dir groups, both files, all three hunks):
--   1 dir  lua/
--   2 block lua/a.lua      (patch line 1)
--   3 hunk  @@ -1,2 +1,2 @@ (patch line 5)
--   4 hunk  @@ -5,1 +5,1 @@ (patch line 9)
--   5 dir  ./
--   6 block b.txt          (patch line 12)
--   7 hunk  @@ -1 +1 @@     (patch line 16)
assert_eq(vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false), {
  ' lua/',
  ' M a.lua   +2 -2',
  '   @@ -1,2 +1,2 @@',
  '   @@ -5,1 +5,1 @@ function bar()',
  ' ./',
  ' M b.txt   +1 -1',
  '   @@ -1 +1 @@',
}, 'fixture rows')

local VIEWED_NS = vim.api.nvim_get_namespaces()['lib.diff.tree.viewed']
assert_true(VIEWED_NS ~= nil, 'the viewed namespace exists')

local ICON = ''

---Tree lines (1-based) whose gutter carries the viewed glyph.
---@param buf? integer defaults to the tree buffer
local function marked(buf)
  local out = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf or tree_buf, 0, -1, false)) do
    if vim.startswith(line, ICON) then
      out[#out + 1] = i
    end
  end
  return out
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(50)
end

local function toggle(lnum)
  vim.api.nvim_set_current_win(tree_win)
  vim.api.nvim_win_set_cursor(tree_win, { lnum, 0 })
  feed('<space>')
end

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

-- The treesitter folds after/ftplugin/git.lua puts on patch windows (`-u NONE`
-- sources no ftplugin): what a viewed file collapses into on the diff side.
vim.wo[src_win].foldmethod = 'expr'
vim.wo[src_win].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo[src_win].foldlevel = 99

assert_eq(marked(), {}, 'nothing is viewed to begin with')

-- ------------------------------------------------------------------
-- A hunk at a time: the file follows once every hunk of it is viewed.
-- ------------------------------------------------------------------
toggle(3)
assert_eq(marked(), { 3 }, 'the first hunk alone is viewed')
assert_eq(src_foldclosed(1), -1, 'a half-reviewed file does not collapse')

toggle(4)
-- Row 1 is the `lua/` header: its only file is viewed, so the group is too.
assert_eq(marked(), { 1, 2, 3, 4 }, 'the last hunk of a file marks the file, and its group')
assert_eq(src_foldclosed(1), 1, "and folds the file's section in the diff")
assert_eq(tree_foldclosed(2), 2, 'and its row in the tree')

-- The mark itself: the glyph replaces the row's blank gutter cell (real text,
-- so a closed fold still shows it), and the rest of the line is dimmed.
assert_eq(
  vim.api.nvim_buf_get_lines(tree_buf, 1, 2, false)[1],
  ICON .. 'M a.lua   +2 -2',
  'the gutter cell became the glyph, the rest of the row is untouched'
)
assert_eq(vim.bo[tree_buf].modifiable, false, 'the tree is left unmodifiable')
local details = vim.api.nvim_buf_get_extmarks(tree_buf, VIEWED_NS, { 1, 0 }, { 1, -1 }, { details = true })
local groups = {}
for _, m in ipairs(details) do
  groups[m[4].hl_group] = { m[3], m[4].end_col }
end
assert_eq(groups.DiffViewedSign, { 0, #ICON }, 'the glyph is coloured on its own')
assert_eq(
  groups.DiffViewed,
  { #ICON, #vim.api.nvim_buf_get_lines(tree_buf, 1, 2, false)[1] },
  'and the label after it is dimmed to the end of the row'
)
-- The row colours (TREE_NS) survive the gutter edit, shifted along with it:
-- the status letter still covers exactly its own cell.
local tree_ns = vim.api.nvim_get_namespaces()['lib.diff.tree']
local status = vim.api.nvim_buf_get_extmarks(tree_buf, tree_ns, { 1, 0 }, { 1, -1 }, { details = true })[1]
assert_eq({ status[3], status[4].end_col }, { #ICON, #ICON + 1 }, 'the status letter mark moved with the text')

-- Unmarking a single hunk clears its file again, and reopens both folds.
toggle(3)
assert_eq(marked(), { 4 }, 'unviewing one hunk unviews its file')
assert_eq({ src_foldclosed(1), tree_foldclosed(2) }, { -1, -1 }, 'and reopens the file on both sides')

-- ------------------------------------------------------------------
-- A file row carries its hunks with it.
-- ------------------------------------------------------------------
toggle(2)
assert_eq(marked(), { 1, 2, 3, 4 }, 'a file row marks the file, every hunk, and its group')
assert_eq({ src_foldclosed(1), tree_foldclosed(2) }, { 1, 2 }, 'and collapses it')

toggle(2)
assert_eq(marked(), {}, 'and clears all of them again')
assert_eq({ src_foldclosed(1), tree_foldclosed(2) }, { -1, -1 }, 'and reopens it')

-- ------------------------------------------------------------------
-- A dir header does its whole group; a group is viewed when its files are.
-- ------------------------------------------------------------------
toggle(1)
assert_eq(marked(), { 1, 2, 3, 4 }, 'the group header, its file and hunks')
assert_eq(src_foldclosed(1), 1, "the group's file collapsed")
assert_eq(src_foldclosed(12), -1, 'the other group is untouched')

toggle(6)
assert_eq(marked(), { 1, 2, 3, 4, 5, 6, 7 }, "the second group's header follows its only file")
assert_eq(src_foldclosed(12), 12, 'and that file collapsed too')

toggle(5)
assert_eq(marked(), { 1, 2, 3, 4 }, 'toggling a fully viewed group clears it')
assert_eq(src_foldclosed(12), -1, 'and reopens its files')

-- ------------------------------------------------------------------
-- The same flags in the diff buffer: a sign on every viewed hunk's `@@`
-- header, and the file's flag as a chunk of lib.diff_filepath's bar.
-- ------------------------------------------------------------------
local SRC_NS = vim.api.nvim_get_namespaces()['lib.diff.viewed']
assert_true(SRC_NS ~= nil, 'the diff-buffer viewed namespace exists')

---{patch line, sign, hl} per viewed-hunk mark in the diff buffer.
local function src_marks()
  local out = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, SRC_NS, 0, -1, { details = true })) do
    out[#out + 1] = { m[2] + 1, m[4].sign_text, m[4].sign_hl_group, m[4].hl_group, m[4].end_col }
  end
  table.sort(out, function(a, b)
    return a[1] < b[1]
  end)
  return out
end

-- `lua/a.lua`'s two hunks are viewed (patch lines 5 and 9), `b.txt`'s is not.
-- The sign comes back padded to the sign column's two cells.
local SIGN = ICON .. ' '
assert_eq(src_marks(), {
  { 5, SIGN, 'DiffViewedSign', 'DiffViewed', #'@@ -1,2 +1,2 @@' },
  { 9, SIGN, 'DiffViewedSign', 'DiffViewed', #'@@ -5,1 +5,1 @@ function bar()' },
}, "a sign on each viewed hunk's @@ header, dimmed to the end of that line only")

-- The file rides in its bar instead: the same glyph as the first chunk.
local bar_ns = vim.api.nvim_get_namespaces()['nvim.diff_filepath']
local function bar_chunks(row)
  local m = vim.api.nvim_buf_get_extmarks(buf, bar_ns, { row, 0 }, { row, -1 }, { details = true })[1]
  return m and m[4].virt_text or nil
end
-- Row 0 is also the block the tree cursor hovers, so its bar is in the Hover
-- palette — the viewed chunk follows it like every other chunk does.
assert_eq(bar_chunks(0), {
  { ICON .. ' ', 'DiffFileBarHoverViewed' },
  { 'lua/a.lua', 'DiffFileBarHoverPath' },
  { ' +2 -2', 'DiffFileBarHoverSummary' },
}, "the viewed file's bar leads with the glyph")
assert_eq(bar_chunks(11), {
  { 'b.txt', 'DiffFileBarPath' },
  { ' +1 -1', 'DiffFileBarSummary' },
}, 'an unviewed file keeps its plain bar')
assert_eq(Diff.file_viewed(buf, 'lua/a.lua'), true, 'file_viewed reports the flag')
assert_eq(Diff.file_viewed(buf, 'b.txt'), false, 'and its absence')

-- ------------------------------------------------------------------
-- The flags live on the diff buffer: closing the sidebar keeps them.
-- ------------------------------------------------------------------
assert_eq(vim.b[buf].diff_tree_viewed, {
  ['f:lua/a.lua'] = true,
  ['h:lua/a.lua:5'] = true,
  ['h:lua/a.lua:9'] = true,
}, 'state stored per file / per hunk on the diff buffer')

vim.api.nvim_set_current_win(tree_win)
feed('s') -- close
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'the sidebar closed')

vim.api.nvim_set_current_win(src_win)
Diff.open_tree()
local reopened = vim.api.nvim_get_current_buf()
assert_true(reopened ~= tree_buf, 'a fresh tree buffer')
assert_eq(marked(reopened), { 1, 2, 3, 4 }, 'the marks are repainted when the tree reopens')
assert_eq(#src_marks(), 2, 'and the diff buffer still carries its hunk signs')

-- Clearing a flag clears both surfaces.
vim.api.nvim_set_current_win(vim.api.nvim_get_current_win())
vim.api.nvim_win_set_cursor(0, { 2, 0 })
feed('<space>')
assert_eq(src_marks(), {}, 'unviewing the file drops its hunk signs')
assert_eq(bar_chunks(0), {
  { 'lua/a.lua', 'DiffFileBarHoverPath' },
  { ' +2 -2', 'DiffFileBarHoverSummary' },
}, 'and its bar loses the glyph')

print('OK: DiffTree viewed marks')
vim.cmd('qa!')
