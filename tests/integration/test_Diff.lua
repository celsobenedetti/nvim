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
-- No mini.icons under -u NONE, so labels are bare paths. Rows are padded:
-- lnums to the widest (2), labels to the widest (11: newfile.txt).
assert_eq(items, {
  { bufnr = buf, lnum = 1, text = ' foo.txt      +1 -1' },
  { bufnr = buf, lnum = 9, text = ' newfile.txt  +1' },
  { bufnr = buf, lnum = 16, text = 'logo.png    ' },
  { bufnr = buf, lnum = 19, text = 'renamed.txt ' },
  { bufnr = buf, lnum = 23, text = 'work.txt     +1 -1' },
}, 'tabular qf rows: lnum at header, aligned path + change summary')

-- Non-patch content parses to ERROR nodes, no blocks -> no items.
local empty = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(empty, 0, -1, false, { 'commit abc123', '    some subject' })
vim.bo[empty].filetype = 'git'
assert_eq(require('lib.Diff').parse_items(empty), {}, 'no blocks, no items')

-- ------------------------------------------------------------------
-- <CR> in the qf window must reuse the window showing the diff buffer
-- instead of splitting a new one. Native nvim jump only reuses windows
-- whose buffer is a normal buffer; fugitive's Git output buffers are
-- buftype=nowrite (autoload/fugitive.vim:3357), so a tab with only the
-- diff + qf windows has no normal buffer and the default <CR> splits
-- (qf_find_win_with_normal_buf -> qf_open_new_file_win).
-- lib.Diff.install_qf_jump works around it. The tab must contain NO
-- normal-buffer window here, or native cc would reuse that one and the
-- test would pass for the wrong reason.
local diff_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, {
  'diff --git a/a.txt b/a.txt',
  'index 1111111..2222222 100644',
  '@@ -1 +1 @@',
  '-x',
  '+y',
})
vim.bo[diff_buf].filetype = 'git'
vim.bo[diff_buf].buftype = 'nowrite' -- as fugitive sets on Git output buffers

vim.api.nvim_win_set_buf(0, diff_buf) -- reuse the initial window: no normal buffer left in the tab
vim.fn.setqflist({}, ' ', {
  title = 'Diff (working tree)',
  items = {
    { bufnr = diff_buf, lnum = 3, text = 'a.txt' },
    { bufnr = diff_buf, lnum = 5, text = 'b.txt' },
  },
})
vim.cmd('botright copen')
require('lib.Diff').install_qf_jump()

local wins_before = #vim.api.nvim_tabpage_list_wins(0)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'x', false)
vim.wait(300)
assert_eq(#vim.api.nvim_tabpage_list_wins(0), wins_before, 'no new window on <CR>')
assert_eq(vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win()), diff_buf, 'cursor lands in diff window')
assert_eq(vim.fn.line('.'), 3, 'cursor at qf entry 1 lnum')

-- back to the qf window, move to entry 2: jump follows the cursor line,
-- not the list's idx (native <CR> is `:.cc`).
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-w>pj<CR>', true, false, true), 'x', false)
vim.wait(300)
assert_eq(#vim.api.nvim_tabpage_list_wins(0), wins_before, 'still no new window')
assert_eq(vim.fn.line('.'), 5, 'cursor at qf entry 2 lnum')

print('OK: lib.Diff treesitter quickfix items')
vim.cmd('qa!')
