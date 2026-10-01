-- Integration test (real nvim, headless): `<space>` in the **diff buffer**
-- (after/ftplugin/git.lua -> lib.Diff.src_row_action), the same row action
-- the DiffTree binds. Covers staging the hunk the diff cursor sits in for a
-- no-arg `:Diff` (`diff_stageable`), that focus stays in the diff window
-- across the refresh, the viewed toggle on a non-stageable diff, and that a
-- closed tree is a no-op rather than an error.
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

-- Under -u NONE nothing sources ftplugins: turn it on so FileType git loads
-- after/ftplugin/git.lua (the `<space>` mapping under test).
vim.cmd('filetype plugin on')

-- ------------------------------------------------------------------
-- A throwaway repo: twenty-line `lua/a.txt` changed at lines 2 and 20 (two
-- `@@` hunks, far enough apart that git does not coalesce them).
-- ------------------------------------------------------------------
local repo = vim.fn.tempname()
vim.fn.mkdir(repo .. '/lua', 'p')

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

local original = {}
for i = 1, 20 do
  original[i] = 'line' .. i
end
write('lua/a.txt', table.concat(original, '\n') .. '\n')
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

vim.cmd.cd(repo)

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

---A patch buffer holding the current `git diff`, shown in the current window,
---with the sidebar open and focus back where `<space>` is pressed from: the
---diff window.
---@param stageable boolean the flag `patch_tab` sets for a no-arg `:Diff`
---@return integer buf, integer win
local function open_diff(stageable)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(run('git', 'diff'), '\n'))
  vim.bo[buf].filetype = 'git'
  vim.b[buf].diff_stageable = stageable or nil
  vim.api.nvim_win_set_buf(0, buf)
  assert_true(wait_parse(buf), 'diff parser parsed buffer')
  local win = vim.api.nvim_get_current_win()
  Diff.open_tree()
  vim.api.nvim_set_current_win(win)
  return buf, win
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(80)
end

---The diff-buffer line inside the body of the nth hunk row of the tree: one
---past its `@@` header, so the cursor is where a reader of the patch is, not
---on a section header.
---@param tree_buf integer
---@param n integer
---@return integer lnum
local function hunk_body_line(tree_buf, n)
  local seen = 0
  for _, r in ipairs(vim.b[tree_buf].diff_tree_rows or {}) do
    if r.kind == 'hunk' then
      seen = seen + 1
      if seen == n then
        return r.lnum + 1
      end
    end
  end
  error('no hunk row ' .. n)
end

local function tree_window()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == 'diff-tree' then
      return w, vim.api.nvim_win_get_buf(w)
    end
  end
  return nil, nil
end

vim.o.lines = 30

-- ------------------------------------------------------------------
-- Stageable diff: `<space>` on a hunk body line stages that `@@` section.
-- ------------------------------------------------------------------
local buf, win = open_diff(true)
local _, tree_buf = tree_window()
assert_true(tree_buf ~= nil, 'tree open')
assert_eq(run('git', 'diff', '--cached', '--', 'lua/a.txt'), '', 'nothing staged yet')

vim.api.nvim_win_set_cursor(win, { hunk_body_line(tree_buf, 1), 0 })
feed('<space>')

local staged = run('git', 'diff', '--cached', '--', 'lua/a.txt')
assert_true(staged:find('line2!CHANGED') ~= nil, 'hunk 1 staged from the diff buffer')
assert_true(staged:find('line20!CHANGED') == nil, 'hunk 2 left alone')

-- The refresh rebuilds the sidebar (which ends with focus in it when pressed
-- from the tree); from the diff buffer focus comes back to the diff window.
assert_eq(vim.bo[vim.api.nvim_get_current_buf()].filetype, 'git', 'focus stayed in the diff window')

-- ------------------------------------------------------------------
-- Non-stageable diff (a revision / `--cached` view: no `diff_stageable`):
-- `<space>` toggles the viewed mark of the section instead, and toggling the
-- same line again clears it.
-- ------------------------------------------------------------------
run('git', 'reset', '-q')
local buf2, win2 = open_diff(false)
local _, tree_buf2 = tree_window()
assert_true(tree_buf2 ~= nil, 'tree open for the non-stageable diff')
assert_eq(vim.b[buf2].diff_tree_viewed, nil, 'nothing viewed yet')

local body = hunk_body_line(tree_buf2, 1)
vim.api.nvim_win_set_cursor(win2, { body, 0 })
feed('<space>')

assert_true(next(vim.b[buf2].diff_tree_viewed or {}) ~= nil, 'the hunk under the cursor is viewed')
assert_eq(vim.api.nvim_get_current_win(), win2, 'focus stayed in the diff window')
assert_eq(vim.api.nvim_win_get_cursor(win2)[1], body, 'cursor stayed on the line (no `j` advance)')

feed('<space>')
assert_eq(next(vim.b[buf2].diff_tree_viewed or {}), nil, 'second press cleared the mark')

-- ------------------------------------------------------------------
-- No tree open: a warning, not an error, and nothing changes.
-- ------------------------------------------------------------------
Diff.open_tree() -- toggles the sidebar shut (focus is in the diff window)
assert_eq(select(2, tree_window()), nil, 'tree closed')
vim.api.nvim_set_current_win(win2)
local ok = pcall(feed, '<space>')
assert_true(ok, '`<space>` with no tree did not error')
assert_eq(next(vim.b[buf2].diff_tree_viewed or {}), nil, 'still nothing viewed')

print('OK: diff buffer <space>')
