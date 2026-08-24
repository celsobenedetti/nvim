-- Integration test (real nvim, headless): the `ga` staging flow.
--
-- Two pieces: lib.Diff.cursor_block_path() (which per-file `block` of a patch
-- buffer the cursor sits in) and lib.git.add() (stage that path — plain
-- `git add` when untracked, fugitive `Git add -p` when there are unstaged
-- changes, a warning otherwise). Together they back the buffer-local `ga` in
-- after/ftplugin/git.lua.
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

-- The alias from after/plugin/autocmds.lua, mirrored here (-u NONE sources no
-- config). Must precede setting filetype=git.
vim.treesitter.language.register('diff', 'git')

-- lib.git notifies through the snacks.nvim global; capture instead.
local notes = {}
_G.Snacks = {
  notify = {
    info = function(msg)
      notes[#notes + 1] = { 'info', msg }
    end,
    warn = function(msg)
      notes[#notes + 1] = { 'warn', msg }
    end,
    error = function(msg)
      notes[#notes + 1] = { 'error', msg }
    end,
  },
}

local function last_note()
  return notes[#notes]
end

-- ------------------------------------------------------------------
-- lib.Diff.cursor_block_path: the file section under the cursor.
-- ------------------------------------------------------------------
local Diff = require('lib.Diff')

-- A `:Git log -p`-shaped buffer: a commit header (outside every block) then
-- two file sections. 1-based lines noted below.
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'commit 1234567890abcdef', -- 1  outside any block
  'diff --git a/a.txt b/a.txt', -- 2  block 1
  'index 1111111..2222222 100644', -- 3
  '--- a/a.txt', -- 4
  '+++ b/a.txt', -- 5
  '@@ -1,2 +1,2 @@', -- 6
  '-old line', -- 7
  '+new line', -- 8
  'diff --git a/dir/b.txt b/dir/b.txt', -- 9  block 2
  'index 3333333..4444444 100644', -- 10
  '--- a/dir/b.txt', -- 11
  '+++ b/dir/b.txt', -- 12
  '@@ -1 +1 @@', -- 13
  '-a', -- 14
  '+b', -- 15
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
assert(parsed, 'diff parser parsed buffer')

local function path_at(line)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  return Diff.cursor_block_path(0)
end

assert_eq(path_at(2), 'a.txt', 'cursor on the `diff --git` header')
assert_eq(path_at(7), 'a.txt', 'cursor inside block 1')
assert_eq(path_at(9), 'dir/b.txt', 'cursor on block 2 header')
assert_eq(path_at(15), 'dir/b.txt', 'cursor in the last hunk')
assert_eq(path_at(1), nil, 'cursor on a commit header: no block')

-- ------------------------------------------------------------------
-- lib.git.add against a throwaway repo.
-- ------------------------------------------------------------------
local git = require('lib.git')

local repo = vim.fn.tempname()
vim.fn.mkdir(repo .. '/dir', 'p')

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

run('git', 'init', '-q')
run('git', 'config', 'user.email', 'test@example.com')
run('git', 'config', 'user.name', 'test')
write('tracked.txt', 'one\n')
write('clean.txt', 'clean\n')
run('git', 'add', '-A')
run('git', 'commit', '-qm', 'init')

write('tracked.txt', 'one\ntwo\n') -- unstaged change
write('dir/new.txt', 'new\n') -- untracked, inside a directory

-- Relative paths resolve against the work-tree root of the cwd (patch buffers
-- yield root-relative paths), so run from inside the repo.
vim.cmd.cd(repo)

local function status(rel)
  return run('git', 'status', '--porcelain', '-uall', '--', rel):sub(1, 2)
end

-- Untracked: staged wholesale.
git.add('dir/new.txt')
assert_eq(status('dir/new.txt'), 'A ', 'untracked file staged')
assert_eq(last_note(), { 'info', 'Added: `dir/new.txt`' }, 'untracked notification')

-- Clean: nothing to do.
git.add('clean.txt')
assert_eq(last_note(), { 'warn', 'No changes: `clean.txt`' }, 'clean file warns')

-- Already staged, nothing left in the work tree: also nothing to do.
git.add('dir/new.txt')
assert_eq(last_note(), { 'warn', 'No changes: `dir/new.txt`' }, 'staged-only file warns')

-- Absolute paths work too (the `ga` in a normal buffer passes none, and falls
-- back to the buffer name, which is absolute).
git.add(repo .. '/clean.txt')
assert_eq(last_note(), { 'warn', 'No changes: `clean.txt`' }, 'absolute path warns, message relative')

-- Unstaged changes: hand off to fugitive's interactive add. `:Git add -p` needs
-- a terminal (and a user), so assert the command instead of running it.
local real_cmd = vim.cmd
local commands = {}
---@diagnostic disable-next-line: duplicate-set-field
vim.cmd = function(c)
  if type(c) == 'string' then
    commands[#commands + 1] = c
    return
  end
  return real_cmd(c)
end
git.add('tracked.txt')
vim.cmd = real_cmd
assert_eq(commands, { 'vertical Git add -p -- ' .. vim.fn.fnameescape(repo .. '/tracked.txt') }, 'add -p command')

-- Outside a repo: warn, never touch git.
local outside = vim.fn.tempname()
vim.fn.mkdir(outside, 'p')
vim.cmd.cd(outside)
git.add('nope.txt')
assert_eq(last_note(), { 'warn', 'not a git repo' }, 'outside a repo warns')

vim.cmd.cd(cwd)
vim.fn.delete(repo, 'rf')
vim.fn.delete(outside, 'rf')

print('OK: diff ga staging flow')
vim.cmd('qa!')
