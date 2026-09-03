-- Integration test (real nvim, headless): staging from the DiffTree in a
-- no-arg `:Diff` (the unstaged working tree) — `<space>` / lib.Diff.
-- tree_stage_row. Covers the row-granularity patch extraction (a hunk row
-- stages its `@@` section, a file row the whole block, a dir header the
-- group), that `git apply --cached` moves exactly those changes into the
-- index of a real throwaway repo, the refresh that re-renders the tree with
-- what was staged gone, and that a non-stageable diff keeps the viewed
-- toggle.
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

-- The alias from after/plugin/autocmds.lua, mirrored here (-u NONE sources no
-- config). Must precede setting filetype=git.
vim.treesitter.language.register('diff', 'git')
_G.lib = require('lib')
local Diff = require('lib.Diff')

-- ------------------------------------------------------------------
-- A throwaway repo: twenty-line `lua/a.txt` with changes at lines 2 and 20
-- (two separate `@@` hunks — far enough apart that git does not coalesce
-- them), and `lib/b.txt` with one change.
-- ------------------------------------------------------------------
local repo = vim.fn.tempname()
vim.fn.mkdir(repo .. '/lua', 'p')
vim.fn.mkdir(repo .. '/lib', 'p')

local function run(...)
  local result = vim.system({ ... }, { cwd = repo }):wait()
  assert(result.code == 0, table.concat({ ... }, ' ') .. ' failed: ' .. tostring(result.stderr))
  return result.stdout or ''
end

local function write(rel, text)
  local f = assert(io.open(repo .. '/' .. rel, 'w'))
  f:write(text)
  f:close()
end

write('lua/a.txt', table.concat({
  'line1',
  'line2',
  'line3',
  'line4',
  'line5',
  'line6',
  'line7',
  'line8',
  'line9',
  'line10',
  'line11',
  'line12',
  'line13',
  'line14',
  'line15',
  'line16',
  'line17',
  'line18',
  'line19',
  'line20',
}, '\n') .. '\n')
write('lib/b.txt', 'a\nb\nc\nd\ne\nf\ng\nh\n')
run('git', 'init', '-q')
run('git', 'config', 'user.email', 'test@example.com')
run('git', 'config', 'user.name', 'test')
run('git', 'add', '-A')
run('git', 'commit', '-qm', 'init')

local changed = {}
for i = 1, 20 do
  changed[i] = i == 2 and 'line2!CHANGED' or (i == 20 and 'line20!CHANGED' or ('line' .. i))
end
write('lua/a.txt', table.concat(changed, '\n') .. '\n')
write('lib/b.txt', 'a\nB\nc\nd\ne\nf\ng\nh\n')

local function git_diff()
  return run('git', 'diff')
end

vim.cmd.cd(repo)

-- ------------------------------------------------------------------
-- Buffer + tree setup: the diff text in a `filetype=git` buffer, the
-- `diff_stageable` flag `patch_tab` sets for a no-arg `:Diff`, and the open
-- sidebar.
-- ------------------------------------------------------------------
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(git_diff(), '\n'))
vim.bo[buf].filetype = 'git'
vim.b[buf].diff_stageable = true
vim.api.nvim_win_set_buf(0, buf)

local function wait_parse(b)
  for _ = 1, 100 do
    if pcall(function()
      return vim.treesitter.get_parser(b):parse()[1]
    end) then
      return true
    end
    vim.wait(50)
  end
  return false
end
assert_true(wait_parse(buf), 'diff parser parsed buffer')

vim.o.lines = 30
local src_win = vim.api.nvim_get_current_win()
Diff.open_tree()
local tree_win = vim.api.nvim_get_current_win()
local tree_buf = vim.api.nvim_win_get_buf(tree_win)

---Flat row labels: `dir <dir>`, `block <path>`, `hunk <@@ line>`. Nil tb
---(no tree open) is the empty list.
local function labels(tb)
  local out = {}
  if tb then
    for i, r in ipairs(vim.b[tb].diff_tree_rows or {}) do
      out[i] = r.kind == 'dir' and ('dir ' .. r.dir)
        or (r.kind == 'block' and ('block ' .. r.path) or ('hunk ' .. r.lnum))
    end
  end
  return out
end

-- git's path sort lists lib/ before lua/. Both a.txt changes are separate
-- hunks: b.txt at line 5, a.txt at lines 16 and 23.
assert_eq(labels(tree_buf), {
  'dir lib/',
  'block lib/b.txt',
  'hunk 5',
  'dir lua/',
  'block lua/a.txt',
  'hunk 16',
  'hunk 23',
}, 'fixture rows: two files, three hunks')

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(80)
end

-- The refresh wipes the old tree buffer (bufhidden=wipe) and opens a fresh
-- one; re-fetch the current tree window/buffer after every stage.
local function current_tree()
  local win = vim.api.nvim_get_current_win()
  -- open_tree leaves focus in the tree; in the non-stageable path it stays
  -- wherever it was. Find the window whose buffer is a tree.
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == 'diff-tree' then
      return w, b
    end
  end
  return nil, nil
end

local function go(win, lnum)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { lnum, 0 })
end

local function index_diff(path)
  return run('git', 'diff', '--cached', '--', path)
end

local function worktree_diff(path)
  return run('git', 'diff', '--', path)
end

-- ------------------------------------------------------------------
-- `<space>` on a hunk stages that `@@` section and nothing else.
-- ------------------------------------------------------------------
assert_eq(index_diff('lua/a.txt'), '', 'nothing staged yet')

-- Row 6 = a.txt's first hunk (`line2!CHANGED`).
go(tree_win, 6)
feed('<space>')

tree_win, tree_buf = current_tree()
assert_true(tree_win ~= nil, 'tree rebuilt after staging')

local staged_a = index_diff('lua/a.txt')
assert_true(staged_a:find('line2!CHANGED') ~= nil, 'hunk 1 staged (line2!CHANGED)')
assert_true(staged_a:find('line20!CHANGED') == nil, 'hunk 2 not staged yet')
local left_a = worktree_diff('lua/a.txt')
assert_true(left_a:find('line2!CHANGED') == nil, 'line2!CHANGED no longer unstaged')
assert_true(left_a:find('line20!CHANGED') ~= nil, 'line20!CHANGED still unstaged')

-- The refresh re-rendered the tree: a.txt now has one hunk, and the cursor
-- sits on the same row index — now hunk 2 (`line20!CHANGED`), so space walks
-- the remaining hunks.
assert_eq(labels(tree_buf), {
  'dir lib/',
  'block lib/b.txt',
  'hunk 5',
  'dir lua/',
  'block lua/a.txt',
  'hunk 16',
}, 'tree rebuilt: hunk 1 gone, hunk 2 remains (now the only hunk of a.txt)')
assert_eq(vim.api.nvim_win_get_cursor(tree_win)[1], 6, 'cursor index keeps the next hunk')

feed('<space>')
tree_win, tree_buf = current_tree()
local staged_a2 = index_diff('lua/a.txt')
assert_true(staged_a2:find('line20!CHANGED') ~= nil, 'hunk 2 staged too')
assert_eq(worktree_diff('lua/a.txt'), '', 'a.txt fully staged: nothing left unstaged')
-- a.txt left the tree entirely; lib/ is untouched.
assert_eq(labels(tree_buf), {
  'dir lib/',
  'block lib/b.txt',
  'hunk 5',
}, 'fully staged file left the tree')
assert_eq(index_diff('lib/b.txt'), '', 'b.txt untouched')

-- ------------------------------------------------------------------
-- A file row stages the whole block.
-- ------------------------------------------------------------------
go(tree_win, 2) -- lib/b.txt
feed('<space>')
tree_win, tree_buf = current_tree()
assert_true(index_diff('lib/b.txt'):find('B') ~= nil, 'whole b.txt staged')
assert_eq(worktree_diff('lib/b.txt'), '', 'b.txt fully staged')
assert_true(index_diff('lua/a.txt'):find('line2!CHANGED') ~= nil, 'a.txt staged changes stay staged')

-- Everything staged: the tree has nothing left (open_tree with zero rows
-- leaves it closed, so current_tree may find no tree at all).
assert_eq(labels(tree_buf or 0), {}, 'nothing left in the tree')

-- ------------------------------------------------------------------
-- A dir header stages its whole group (two files under one dir). Reset
-- a.txt's index entry to the committed base (its work-tree version carries
-- the two changes again) and intent-to-add c.txt so both appear in git
-- diff under lua/.
-- ------------------------------------------------------------------
run('git', 'reset', '-q', 'lua/a.txt')
write('lua/c.txt', 'x\nY\nz\nw\n')
run('git', 'add', '-N', 'lua/c.txt')

local buf2 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf2, 0, -1, false, vim.split(git_diff(), '\n'))
vim.bo[buf2].filetype = 'git'
vim.b[buf2].diff_stageable = true
vim.api.nvim_win_set_buf(0, buf2)
assert_true(wait_parse(buf2), 'second diff parsed')

vim.api.nvim_set_current_win(vim.api.nvim_get_current_win())
local src_win2 = vim.api.nvim_get_current_win()
Diff.open_tree()
local tree_win2 = vim.api.nvim_get_current_win()
local tree_buf2 = vim.api.nvim_win_get_buf(tree_win2)
-- lua/ (a.txt + c.txt), lib/ (b.txt now clean? no — b.txt was fully staged,
-- so the fresh diff has only lua/).
assert_eq(labels(tree_buf2), {
  'dir lua/',
  'block lua/a.txt',
  'hunk 5',
  'hunk 12',
  'block lua/c.txt',
  'hunk 23',
}, 'one group with two files')

go(tree_win2, 1) -- the lua/ header
feed('<space>')
tree_win2, tree_buf2 = current_tree()
assert_true(index_diff('lua/a.txt'):find('line2!CHANGED') ~= nil, 'dir header staged a.txt')
assert_true(index_diff('lua/c.txt'):find('Y') ~= nil, 'dir header staged c.txt')
assert_eq(worktree_diff('lua/a.txt'), '', 'a.txt fully staged')
assert_eq(worktree_diff('lua/c.txt'), '', 'c.txt fully staged')
-- The whole group left the tree: the rebuilt sidebar has nothing left to
-- show, so it is closed (open_tree with zero rows returns without opening).
assert_eq(labels(tree_buf2 or 0), {}, 'the group left the tree')

-- ------------------------------------------------------------------
-- A non-stageable diff (revision / --cached: no `diff_stageable`) keeps the
-- viewed toggle: `<space>` marks viewed and never touches git.
-- ------------------------------------------------------------------
local buf3 = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf3, 0, -1, false, {
  'diff --git a/foo.txt b/foo.txt', -- 1 block
  'index 1111111..2222222 100644', --  2
  '--- a/foo.txt', --                 3
  '+++ b/foo.txt', --                 4
  '@@ -1 +1 @@', --                   5 hunk
  '-a', --                            6
  '+b', --                            7
})
vim.bo[buf3].filetype = 'git'
vim.api.nvim_win_set_buf(0, buf3)
assert_true(wait_parse(buf3), 'non-stageable diff parsed')

Diff.open_tree()
local tree_win3 = vim.api.nvim_get_current_win()
local tree_buf3 = vim.api.nvim_win_get_buf(tree_win3)
vim.api.nvim_set_current_win(tree_win3)
vim.api.nvim_win_set_cursor(tree_win3, { 2, 0 }) -- the block row
feed('<space>')
-- Viewed toggle paints the glyph in the gutter; git is untouched.
assert_eq(
  vim.api.nvim_buf_get_lines(tree_buf3, 1, 2, false)[1],
  '\u{f00c}' .. 'M foo.txt   +1 -1',
  'viewed toggle, no stage'
)
assert_eq(index_diff('foo.txt'), '', 'git untouched in non-stageable mode')

print('OK: DiffTree staging')
vim.cmd('qa!')
