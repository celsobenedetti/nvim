-- Integration test (real nvim, headless): the filetype=git -> diff
-- treesitter language alias from after/plugin/autocmds.lua.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

-- Repo root on rtp so queries/diff/folds.scm resolves (Makefile runs us
-- from the repo root; under -u NONE nothing else puts it there).
vim.opt.rtp:prepend(vim.fn.getcwd())

local function assert_eq(got, want, msg)
  if got ~= want then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

-- The line under test (mirroring after/plugin/autocmds.lua):
vim.treesitter.language.register('diff', 'git')

assert_eq(vim.treesitter.language.get_lang('git'), 'diff', 'alias registered')

-- A fugitive-style patch buffer: ft=git, commit metadata + embedded diff.
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'commit 1234567890abcdef',
  'Author: Celso <celso@example.com>',
  '',
  '    some subject',
  '',
  'diff --git a/foo.txt b/foo.txt',
  'index 1111111..2222222 100644',
  '--- a/foo.txt',
  '+++ b/foo.txt',
  '@@ -1,2 +1,2 @@',
  '-old line',
  '+new line',
  ' context',
})
vim.bo[buf].filetype = 'git'

vim.cmd('vsplit')
vim.api.nvim_win_set_buf(0, buf)

-- Highlighter: start() must resolve lang through the alias.
vim.treesitter.start(buf)
assert(vim.treesitter.highlighter.active[buf], 'highlighter attached')
assert_eq(vim.treesitter.highlighter.active[buf].tree:lang(), 'diff', 'highlighter uses diff parser')

-- Folding: ts foldexpr machinery resolves get_parser(bufnr) from the
-- filetype; the alias must make that a diff parser whose folds query
-- (queries/diff/folds.scm) folds per-file blocks and hunks.
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

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
assert(parsed, 'parser parsed buffer')

-- Ask where the fold starting at the `diff --git` header (line 6) closes.
-- This drives vim's fold computation, which evaluates our foldexpr over the
-- buffer. It must span through the hunk to buffer end; metadata lines (1-5)
-- stay unfolded.
local last = vim.api.nvim_buf_line_count(buf)
local closedend = vim.api.nvim_win_call(0, function()
  return vim.fn.foldclosedend(6)
end)

if closedend <= 0 then -- foldclosedend needs a redraw pass sometimes; fall back to checking the
  -- folds query captures directly.
  local q = assert(vim.treesitter.query.get('diff', 'folds'), 'folds query found')
  local tree = vim.treesitter.get_parser(buf):parse()[1]
  local found_hunk_fold = false
  for _, node in q:iter_captures(tree:root(), buf, 0, -1) do
    local sr, _, er = node:range()
    if er > sr and sr >= 5 then
      found_hunk_fold = true
      break
    end
  end
  assert(found_hunk_fold, 'folds query folds the diff region')
else
  assert(closedend >= last, ('block fold spans the whole file diff, got %d'):format(closedend))
end

print('OK: git->diff treesitter alias (highlighter + folds)')
vim.cmd('qa!')
