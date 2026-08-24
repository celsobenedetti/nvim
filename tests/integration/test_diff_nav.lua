-- Integration test (real nvim, headless): diff-section navigation keymaps.
--
-- lib.Diff.goto_node() walks the `diff` treesitter tree (`block` = per-file
-- `diff --git` section, `hunk` = per-hunk `@@` section) and jumps the cursor
-- to the count-th matching node before/after the cursor. The keymaps live in
-- after/ftplugin/git.lua (`[`/`]` hunks, `,`/`.` blocks); this test loads them
-- by sourcing ftplugins (`filetype plugin on` + the repo's after/ on rtp) and
-- feeds real keys, in addition to calling goto_node directly.
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

-- The alias from after/plugin/autocmds.lua, mirrored here (under -u NONE
-- nothing sources the live config). Must precede setting filetype=git.
vim.treesitter.language.register('diff', 'git')

-- after/ftplugin/git.lua refers to the global `lib`; the live config sets
-- `_G.lib` in lua/init/globals.lua, which -u NONE skips.
_G.lib = require('lib')

-- Under -u NONE nothing sources ftplugins: turn it on so FileType git
-- loads after/ftplugin/git.lua (the keymaps under test).
vim.cmd('filetype plugin on')

-- A fugitive-style patch buffer: two blocks, three hunks.
-- 0-based start rows: block=0,11  hunk=4,8,15.
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'diff --git a/a.txt b/a.txt', -- 1
  'index 1111111..2222222 100644', -- 2
  '--- a/a.txt', -- 3
  '+++ b/a.txt', -- 4
  '@@ -1,2 +1,2 @@', -- 5  hunk 1
  '-old line', -- 6
  '+new line', -- 7
  ' context', -- 8
  '@@ -5,1 +5,1 @@', -- 9  hunk 2
  '-x', -- 10
  '+y', -- 11
  'diff --git a/b.txt b/b.txt', -- 12  block 2
  'index 3333333..4444444 100644', -- 13
  '--- a/b.txt', -- 14
  '+++ b/b.txt', -- 15
  '@@ -1 +1 @@', -- 16  hunk 3
  '-a', -- 17
  '+b', -- 18
})
-- Make it the current buffer before FileType fires so the ftplugin's
-- `buffer = 0` keymaps land on it (and cursor ops below target it).
vim.api.nvim_win_set_buf(0, buf)
vim.bo[buf].filetype = 'git'

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
assert(parsed, 'diff parser parsed buffer')

local Diff = require('lib.Diff')

local function cursor()
  return vim.fn.line('.') -- 1-based
end

local function set_cursor(line)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

-- ------------------------------------------------------------------
-- lib.Diff.goto_node directly.
-- ------------------------------------------------------------------
-- next hunk: skips past the node the cursor is on (strict >).
set_cursor(1)
Diff.goto_node('hunk', 1)
assert_eq(cursor(), 5, '] from block header -> first hunk')
set_cursor(5)
Diff.goto_node('hunk', 1)
assert_eq(cursor(), 9, '] from hunk 1 -> hunk 2')
set_cursor(11)
Diff.goto_node('hunk', 1)
assert_eq(cursor(), 16, '] from hunk 2 -> hunk 3')
set_cursor(16)
Diff.goto_node('hunk', 1)
assert_eq(cursor(), 16, '] from last hunk: no-op')

-- previous hunk: from mid-hunk goes to the current hunk's header.
set_cursor(18)
Diff.goto_node('hunk', -1)
assert_eq(cursor(), 16, '[ from end -> hunk 3')
set_cursor(16)
Diff.goto_node('hunk', -1)
assert_eq(cursor(), 9, '[ from hunk 3 -> hunk 2')
set_cursor(7) -- mid hunk 1
Diff.goto_node('hunk', -1)
assert_eq(cursor(), 5, '[ from mid-hunk -> current hunk header')
set_cursor(5)
Diff.goto_node('hunk', -1)
assert_eq(cursor(), 5, '[ from first hunk: no-op')

-- blocks.
set_cursor(1)
Diff.goto_node('block', 1)
assert_eq(cursor(), 12, '. from block 1 -> block 2')
set_cursor(12)
Diff.goto_node('block', 1)
assert_eq(cursor(), 12, '. from last block: no-op')
set_cursor(18)
Diff.goto_node('block', -1)
assert_eq(cursor(), 12, ', from end -> block 2')
set_cursor(12)
Diff.goto_node('block', -1)
assert_eq(cursor(), 1, ', from block 2 -> block 1')
set_cursor(1)
Diff.goto_node('block', -1)
assert_eq(cursor(), 1, ', from first block: no-op')

-- ------------------------------------------------------------------
-- The keymaps from after/ftplugin/git.lua (installed via FileType git).
-- Feed real keys, including a count.
-- ------------------------------------------------------------------
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
  vim.wait(50)
end

set_cursor(2)
feed(']')
assert_eq(cursor(), 5, 'keymap ] -> next hunk')
feed(']')
assert_eq(cursor(), 9, 'keymap ] again -> next hunk')
feed('[')
assert_eq(cursor(), 5, 'keymap [ -> previous hunk')

set_cursor(1)
feed('2]')
assert_eq(cursor(), 9, 'keymap 2] -> second next hunk')

set_cursor(3)
feed('.')
assert_eq(cursor(), 12, 'keymap . -> next file')
feed(',')
assert_eq(cursor(), 1, 'keymap , -> previous file')

print('OK: diff navigation keymaps')
vim.cmd('qa!')
