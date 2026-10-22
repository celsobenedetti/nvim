-- Integration test (real nvim, headless): :OrgFocus renders a single org
-- subtree in its own buffer and `:w` splices it back into the source file
-- without touching anything outside the subtree. Guards: a source buffer with
-- unsaved changes or a moved headline abort the write, `:e!` re-reads.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
vim.opt.rtp:append(cwd .. '/after')
vim.opt.rtp:prepend(vim.fn.expand('~/.local/share/nvim/lazy/nvim-orgmode'))
package.path = cwd .. '/lua/?.lua;' .. package.path
vim.cmd('filetype plugin on')

local function assert_eq(got, want, msg)
  if got ~= want then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

vim.cmd('luafile ' .. cwd .. '/lua/init/globals.lua')

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local file = dir .. '/messy.org'
local original = {
  '#+title: messy',
  'intro before the first headline',
  '',
  '* NEXT take out trash :home:',
  '  SCHEDULED: <2026-01-02 Fri>',
  '  :PROPERTIES:',
  '  :ID: abc-123',
  '  :END:',
  '',
  '* PROG focus me :work:',
  '  Body of focus me.',
  '',
  '  ** child one',
  '     child body',
  '',
  '  | a | b |',
  '  |---+---|',
  '  | 1 | 2 |',
  '',
  '  #+begin_src lua',
  "  print('hi')",
  '  #+end_src',
  '',
  '** sibling',
  '   trailing',
}
vim.fn.writefile(original, file)

require('orgmode').setup({ org_agenda_files = { dir .. '/*.org' } })
vim.cmd.edit(file)
lib.org_focus.setup_commands()

-- Focus the headline under the cursor.
vim.api.nvim_win_set_cursor(0, { 10, 0 })
vim.cmd('OrgFocus')
local focus = vim.api.nvim_get_current_buf()
assert_eq(vim.bo[focus].filetype, 'org', 'the focus buffer is an org buffer')
assert_eq(vim.bo[focus].buftype, 'acwrite', ':w is intercepted by the focus buffer')
assert_eq(vim.bo[focus].buflisted, false, 'the focus buffer stays out of the buffer list')
local pos = require('orgmode.api').load(file).headlines[2].position
assert_eq(pos.start_line, 10, 'the subtree starts at its headline')
assert_eq(
  table.concat(vim.api.nvim_buf_get_lines(focus, 0, -1, false), '\n'),
  table.concat(vim.api.nvim_buf_get_lines(vim.fn.bufnr(file), pos.start_line - 1, pos.end_line, false), '\n'),
  'the focus buffer holds exactly the subtree'
)

-- An edit in the focus buffer lands inside the subtree, on disk, and nowhere else.
vim.api.nvim_buf_set_lines(focus, 1, 1, false, { '  EDITED IN FOCUS' })
vim.cmd('write')
assert_eq(vim.bo[focus].modified, false, 'the focus buffer is clean after writing')
local written = vim.fn.readfile(file)
assert_eq(written[11], '  EDITED IN FOCUS', 'the edit was spliced into the source file')
assert_eq(#written, #original + 1, 'only one line was added')
assert_eq(written[4], original[4], 'the previous headline is untouched')
assert_eq(written[#written], '   trailing', 'the trailing content is untouched')

-- A second write of a grown subtree keeps tracking the right range.
vim.api.nvim_buf_set_lines(focus, 0, 1, false, { '** renamed in focus' })
vim.cmd('write')
written = vim.fn.readfile(file)
assert_eq(written[10], '** renamed in focus', 'the headline line itself was spliced')
assert_eq(written[#written], '   trailing', 'still nothing past the subtree')

-- `:e!` re-reads the subtree from the source (read side of the sync).
vim.api.nvim_buf_set_lines(vim.fn.bufnr(file), 10, 11, false, { '  changed in source' })
vim.cmd('edit!')
assert_eq(
  vim.api.nvim_buf_get_lines(focus, 1, 2, false)[1],
  '  changed in source',
  ':e! re-read the subtree from the source buffer'
)

-- A moved headline aborts the write instead of clobbering the wrong lines.
local src = vim.fn.bufnr(file)
vim.api.nvim_buf_set_lines(src, 9, 10, false, { '** moved elsewhere' })
vim.api.nvim_buf_call(src, function()
  vim.cmd('silent write') -- saved, so only staleness can abort the next write
end)
vim.api.nvim_buf_set_lines(focus, 1, 2, false, { '  should not land' })
vim.cmd('write')
assert_eq(vim.bo[focus].modified, true, 'the aborted write leaves the focus buffer dirty')
vim.cmd('silent! write!')
assert_eq(vim.bo[focus].modified, true, ':w! is guarded too')
assert_eq(vim.fn.readfile(file)[10], '** moved elsewhere', 'the moved headline is untouched')
assert_eq(vim.fn.readfile(file)[11], '  changed in source', 'the source is unchanged after the abort')

-- A conflicting edit inside the same subtree is refused, not clobbered.
vim.fn.writefile(original, file)
vim.api.nvim_win_set_buf(0, src)
vim.api.nvim_buf_call(src, function()
  vim.cmd('edit!')
end)
vim.api.nvim_win_set_cursor(0, { 10, 0 })
vim.cmd('OrgFocus')
focus = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(focus, 1, 2, false, { '  conflicting focus edit' })
vim.api.nvim_buf_set_lines(src, 10, 11, false, { '  conflicting source edit' })
vim.cmd('write')
assert_eq(vim.bo[focus].modified, true, 'a conflicting subtree write is refused')
assert_eq(vim.fn.readfile(file)[11], original[11], 'the source file was not written')

-- `:e!` resyncs onto the source, even when the source moved on.
vim.cmd('edit!')
assert_eq(
  vim.api.nvim_buf_get_lines(focus, 1, 2, false)[1],
  '  conflicting source edit',
  ':e! takes the source buffer state'
)

-- :OrgFocus inside a focus buffer leaves for the real headline.
vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.cmd('OrgFocus')
assert_eq(vim.api.nvim_get_current_buf(), src, ':OrgFocus on a focus buffer goes to the source file')
assert_eq(vim.api.nvim_win_get_cursor(0)[1], 10, 'the cursor lands on the headline')

-- Org actions run against the source headline, not against the focus buffer's
-- line numbers (`t` used to fail with "Current file is not a valid org file").
local todo = dir .. '/todo.org'
vim.fn.writefile({ '#+title: t', '', '* TODO focus me', '  body', '', '* other', '  x' }, todo)
vim.cmd('edit ' .. todo)
local todo_src = vim.fn.bufnr(todo)
vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.cmd('OrgFocus')
local todo_focus = vim.api.nvim_get_current_buf()
require('orgmode').action('org_mappings.todo_next_state')
assert_eq(
  vim.api.nvim_buf_get_lines(todo_src, 2, 3, false)[1],
  '* DONE focus me',
  'the todo action hit the source headline'
)
assert_eq(vim.api.nvim_buf_get_lines(todo_src, 0, 1, false)[1], '#+title: t', 'the line above was untouched')
assert_eq(
  vim.api.nvim_buf_get_lines(todo_focus, 0, 1, false)[1],
  '* DONE focus me',
  'the focus buffer mirrors the action'
)
assert_eq(vim.bo[todo_focus].modified, false, 'the action leaves the focus buffer clean')
vim.cmd('write')
assert_eq(vim.fn.readfile(todo)[3], '* DONE focus me', ':w persists the action without a conflict')

-- Re-focusing reuses the buffer and picks up source-side edits made meanwhile.
vim.cmd('OrgFocus')
assert_eq(vim.api.nvim_get_current_buf(), todo_src, 'back on the source headline')
vim.api.nvim_buf_set_lines(todo_src, 3, 4, false, { '  body changed in source' })
vim.cmd('write')
vim.cmd('OrgFocus')
assert_eq(vim.api.nvim_get_current_buf(), todo_focus, 'the focus buffer was reused')
assert_eq(
  vim.api.nvim_buf_get_lines(todo_focus, 1, 2, false)[1],
  '  body changed in source',
  're-focusing pulls the source range again'
)

print('OK')
