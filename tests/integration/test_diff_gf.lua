-- Integration test (real nvim, headless): the `gf` flow of a patch buffer and
-- of the DiffTree sidebar — lib.Diff.file_location (which working-tree line a
-- patch line points at), lib.fs.open_in_first_tab (where it is opened), and
-- the two entry points that join them (lib.Diff.open_cursor_file /
-- lib.Diff.tree_open_file).
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
local fs = require('lib.fs')

-- Warnings go through vim.notify (no file section, file not in the work tree).
local notes = {}
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level)
  notes[#notes + 1] = { msg, level }
end

local function last_note()
  return notes[#notes]
end

-- ------------------------------------------------------------------
-- A throwaway repo: the files the patch below names have to exist in a work
-- tree, because that is what `gf` opens (paths in a patch are root-relative,
-- resolved through lib.git.root).
-- ------------------------------------------------------------------
local repo = vim.fn.tempname()
vim.fn.mkdir(repo .. '/dir', 'p')

local function run(...)
  local result = vim.system({ ... }, { cwd = repo }):wait()
  assert(result.code == 0, table.concat({ ... }, ' ') .. ' failed: ' .. tostring(result.stderr))
end

local function write(rel, lines)
  local f = assert(io.open(repo .. '/' .. rel, 'w'))
  f:write(table.concat(lines, '\n') .. '\n')
  f:close()
end

run('git', 'init', '-q')
-- 60 lines, each naming itself, so a landed cursor identifies its own line.
local numbered = {}
for i = 1, 60 do
  numbered[i] = 'line ' .. i
end
write('a.txt', numbered)
write('dir/b.txt', { 'only line' })

vim.cmd.cd(repo)

-- ------------------------------------------------------------------
-- lib.Diff.file_location: patch line -> (path, line in the file).
-- ------------------------------------------------------------------
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'commit 1234567890abcdef', --      1  outside every block
  'diff --git a/a.txt b/a.txt', --   2  block 1
  'index 1111111..2222222 100644', --3
  '--- a/a.txt', --                  4
  '+++ b/a.txt', --                  5
  '@@ -10,4 +12,5 @@ fn()', --       6  new side starts at 12
  ' ctx', --                         7  -> 12
  '-gone', --                        8  -> 13 (the line that replaced it)
  '+added', --                       9  -> 13
  '+added2', --                     10  -> 14
  ' ctx2', --                       11  -> 15
  '@@ -40,2 +50,3 @@', --           12  second hunk of the same file
  ' c', --                          13  -> 50
  '+n', --                          14  -> 51
  'diff --git a/dir/b.txt b/dir/b.txt', -- 15  block 2
  'index 3333333..4444444 100644', --16
  '--- a/dir/b.txt', --             17
  '+++ b/dir/b.txt', --             18
  '@@ -1 +1 @@', --                 19
  '-a', --                          20
  '+b', --                          21
  'diff --git a/gone.txt b/gone.txt', -- 22  block 3: deleted, no such file
  'index 5555555..0000000 100644', --23
  '--- a/gone.txt', --              24
  '+++ /dev/null', --               25
  '@@ -1 +0,0 @@', --               26
  '-x', --                          27
})
vim.api.nvim_win_set_buf(0, buf)
vim.bo[buf].filetype = 'git'

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

local function at(line)
  local path, lnum = Diff.file_location(buf, line)
  return { path, lnum }
end

assert_eq(at(1), { nil, 1 }, 'a commit header belongs to no block')
assert_eq(at(2), { 'a.txt', 1 }, 'the `diff --git` header opens the file at line 1')
assert_eq(at(5), { 'a.txt', 1 }, 'the `+++` line is still outside every hunk')
assert_eq(at(6), { 'a.txt', 12 }, 'the `@@` header lands on the new-side start')
assert_eq(at(7), { 'a.txt', 12 }, 'first context line')
assert_eq(at(8), { 'a.txt', 13 }, 'a deletion maps to the line that replaced it')
assert_eq(at(9), { 'a.txt', 13 }, 'first addition (the deletion above it does not count)')
assert_eq(at(10), { 'a.txt', 14 }, 'second addition')
assert_eq(at(11), { 'a.txt', 15 }, 'trailing context')
assert_eq(at(12), { 'a.txt', 50 }, 'the second hunk restarts from its own header')
assert_eq(at(14), { 'a.txt', 51 }, 'inside the second hunk')
assert_eq(at(15), { 'dir/b.txt', 1 }, 'block 2 header, path kept root-relative')
assert_eq(at(21), { 'dir/b.txt', 1 }, 'block 2 hunk')
assert_eq(at(27), { 'gone.txt', 1 }, 'a deletion block names its file; its `+0,0` hunk maps to line 1')

-- ------------------------------------------------------------------
-- lib.fs.open_in_first_tab: which window of tab 1 the file lands in.
-- ------------------------------------------------------------------
local tab1 = vim.api.nvim_get_current_tabpage()
local tab1_win = vim.api.nvim_get_current_win()

-- A second tab holds the patch buffer, as `:Diff` does.
vim.cmd('tabnew')
local patch_tab = vim.api.nvim_get_current_tabpage()
vim.api.nvim_win_set_buf(0, buf)

fs.open_in_first_tab(repo .. '/a.txt', 13)
assert_eq(vim.api.nvim_get_current_tabpage(), tab1, 'the file opens in the first tab')
assert_eq(vim.api.nvim_get_current_win(), tab1_win, "reuses that tab's window")
assert_eq(vim.api.nvim_buf_get_name(0), repo .. '/a.txt', 'the file is loaded')
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 13, 'cursor on the requested line')

-- A line past the end of the file is clamped, not an error.
fs.open_in_first_tab(repo .. '/dir/b.txt', 99)
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 1, 'a line past the end clamps to the last one')

-- A window already showing the file is reused, wherever it is in the tab.
vim.cmd('split')
local extra_win = vim.api.nvim_get_current_win()
vim.cmd('edit ' .. repo .. '/a.txt')
vim.api.nvim_set_current_win(tab1_win)
vim.api.nvim_set_current_tabpage(patch_tab)
fs.open_in_first_tab(repo .. '/a.txt', 20)
assert_eq(vim.api.nvim_get_current_win(), extra_win, 'a window already showing the file wins')
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 20, 'and moves to the line')

-- A sidebar (`buftype=nofile`, e.g. an explorer) is never the window that
-- gets replaced: the file goes to a normal one instead.
local side = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(extra_win, side)
vim.api.nvim_set_current_win(extra_win)
vim.api.nvim_set_current_tabpage(patch_tab)
fs.open_in_first_tab(repo .. '/dir/b.txt', 1)
assert_eq(vim.api.nvim_get_current_win(), tab1_win, 'a nofile window is skipped')
assert_eq(vim.api.nvim_buf_get_name(0), repo .. '/dir/b.txt', 'the file went to the normal window')

vim.api.nvim_win_close(extra_win, true)

-- ------------------------------------------------------------------
-- `gf` in the patch buffer (lib.Diff.open_cursor_file).
-- ------------------------------------------------------------------
vim.api.nvim_set_current_tabpage(patch_tab)
vim.api.nvim_win_set_cursor(0, { 10, 0 })
Diff.open_cursor_file()
assert_eq(vim.api.nvim_get_current_tabpage(), tab1, 'gf leaves the diff tab')
assert_eq(vim.api.nvim_buf_get_name(0), repo .. '/a.txt', 'gf opened the block file')
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 14, "gf landed on the patch line's file line")
assert_eq(vim.fn.getline('.'), 'line 14', 'which really is that line of the file')

-- Outside every block: a warning, and the tab stays put.
vim.api.nvim_set_current_tabpage(patch_tab)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
Diff.open_cursor_file()
assert_eq(vim.api.nvim_get_current_tabpage(), patch_tab, 'no file section: no jump')
assert_eq(last_note(), { 'Diff: no file section under the cursor', vim.log.levels.WARN }, 'and a warning')

-- A file the patch deletes is not in the work tree: warn instead of opening.
vim.api.nvim_win_set_cursor(0, { 27, 0 })
Diff.open_cursor_file()
assert_eq(vim.api.nvim_get_current_tabpage(), patch_tab, 'deleted file: no jump')
assert_eq(last_note(), { 'Diff: not in the working tree: gone.txt', vim.log.levels.WARN }, 'and a warning')

-- ------------------------------------------------------------------
-- `gf` in the tree (lib.Diff.tree_open_file): the row's file, at the line its
-- section points at.
-- ------------------------------------------------------------------
vim.api.nvim_set_current_tabpage(patch_tab)
Diff.open_tree()
local tree_buf = vim.api.nvim_get_current_buf()
assert_eq(vim.bo[tree_buf].filetype, 'diff-tree', 'the tree opened and is focused')

local rows = vim.b[tree_buf].diff_tree_rows
local function row_index(kind, lnum)
  for i, r in ipairs(rows) do
    if r.kind == kind and r.lnum == lnum then
      return i
    end
  end
  error(('no %s row for patch line %d'):format(kind, lnum))
end

-- The second hunk of a.txt (patch line 12) -> its new-side start, line 50.
vim.api.nvim_win_set_cursor(0, { row_index('hunk', 12), 0 })
Diff.tree_open_file(tree_buf)
assert_eq(vim.api.nvim_get_current_tabpage(), tab1, 'the tree sends the file to the first tab')
assert_eq(vim.api.nvim_buf_get_name(0), repo .. '/a.txt', "the hunk row's file")
assert_eq(vim.fn.getline('.'), 'line 50', "the hunk's first new-side line")

-- A file row has no hunk of its own: line 1.
vim.api.nvim_set_current_tabpage(patch_tab)
vim.api.nvim_win_set_cursor(0, { row_index('block', 15), 0 })
Diff.tree_open_file(tree_buf)
assert_eq(vim.api.nvim_buf_get_name(0), repo .. '/dir/b.txt', "the file row's file")
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 1, 'a file row opens at line 1')

vim.cmd.cd(cwd)
vim.fn.delete(repo, 'rf')

print('OK: diff gf (open the file under the cursor in the first tab)')
vim.cmd('qa!')
