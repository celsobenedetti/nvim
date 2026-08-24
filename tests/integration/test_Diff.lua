-- Integration test (real nvim, headless): lib.Diff quickfix building via
-- the diff treesitter grammar over fugitive `filetype=git` patch buffers.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

-- Repo root on rtp so `require('lib.*')` resolves (Makefile runs us from
-- the repo root; under -u NONE nothing else puts it there).
vim.opt.rtp:prepend(vim.fn.getcwd())
package.path = vim.fn.getcwd() .. '/lua/?.lua;' .. package.path

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

-- The alias from after/plugin/autocmds.lua, mirrored here (under -u NONE
-- nothing sources the live config).
vim.treesitter.language.register('diff', 'git')

-- A fugitive-style patch buffer: ft=git with several file sections (text
-- hunk, new file, binary, pure rename).
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'diff --git a/foo.txt b/foo.txt',
  'index 1111111..2222222 100644',
  '--- a/foo.txt',
  '+++ b/foo.txt',
  '@@ -1,2 +1,2 @@',
  '-old line',
  '+new line',
  ' context',
  'diff --git a/newfile.txt b/newfile.txt',
  'new file mode 100644',
  'index 0000000..3e75765',
  '--- /dev/null',
  '+++ b/newfile.txt',
  '@@ -0,0 +1 @@',
  '+new',
  'diff --git a/logo.png b/logo.png',
  'index 1234567..89abcde 100644',
  'Binary files a/logo.png and b/logo.png differ',
  'diff --git a/old.txt b/renamed.txt',
  'similarity index 100%',
  'rename from old.txt',
  'rename to renamed.txt',
  -- git >= 2.50 uses i/w prefixes for index/worktree diffs
  'diff --git i/work.txt w/work.txt',
  'index 3582182..260c86e 100644',
  '--- i/work.txt',
  '+++ w/work.txt',
  '@@ -1 +1 @@',
  '-old',
  '+new',
})
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

local items = require('lib.Diff').parse_items(buf)
assert_eq(items, {
  { bufnr = buf, lnum = 1, text = 'foo.txt' },
  { bufnr = buf, lnum = 9, text = 'newfile.txt' },
  { bufnr = buf, lnum = 16, text = 'logo.png' },
  { bufnr = buf, lnum = 19, text = 'renamed.txt' },
  { bufnr = buf, lnum = 23, text = 'work.txt' },
}, 'one quickfix entry per file block, lnum at diff --git header')

-- Non-patch content parses to ERROR nodes, no blocks -> no items.
local empty = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(empty, 0, -1, false, { 'commit abc123', '    some subject' })
vim.bo[empty].filetype = 'git'
assert_eq(require('lib.Diff').parse_items(empty), {}, 'no blocks, no items')

print('OK: lib.Diff treesitter quickfix items')
vim.cmd('qa!')
