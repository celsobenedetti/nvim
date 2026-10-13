-- Integration test (real nvim, headless): gd on a [[wikilink]] inside an org
-- agenda line opens the note in the window above the agenda, picking the vault
-- from the org file the headline comes from (work.org -> work vault).
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
vim.opt.rtp:append(cwd .. '/after')
vim.opt.rtp:prepend(vim.fn.expand('~/.local/share/nvim/lazy/nvim-orgmode'))
vim.opt.rtp:prepend(vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim'))
vim.opt.rtp:prepend(vim.fn.expand('~/.local/share/nvim/lazy/obsidian.nvim'))
package.path = cwd .. '/lua/?.lua;' .. package.path
vim.cmd('filetype plugin on')

local function assert_eq(got, want, msg)
  if got ~= want then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

-- Two vaults and a work.org whose headline links a note that exists in *both*,
-- so resolution proves the work vault was picked, not the garden.
local root = vim.fn.tempname()
local work, garden, org = root .. '/work', root .. '/garden', root .. '/org'
vim.fn.mkdir(work, 'p')
vim.fn.mkdir(garden, 'p')
vim.fn.mkdir(org, 'p')
vim.fn.writefile({ '# standup' }, work .. '/standup.md')
vim.fn.writefile({ '# standup' }, garden .. '/standup.md')
vim.fn.writefile({ '* TODO Prep [[standup]] notes', '  DEADLINE: ' .. os.date('<%Y-%m-%d %a>') }, org .. '/work.org')

vim.cmd('luafile ' .. cwd .. '/lua/init/globals.lua')
-- Point the vault routing at the throwaway dirs instead of the real notes.
config.dirs.notes, config.dirs.garden, config.dirs.work_notes = root, garden, work
config.org.work = org .. '/work.org'

require('obsidian').setup({ workspaces = { { name = 'garden', path = garden }, { name = 'work', path = work } } })
require('orgmode').setup({ org_agenda_files = { org .. '/*.org' } })

-- Like the real config: orgmode's `:34split orgagenda` puts the agenda below.
vim.o.splitbelow = true

vim.cmd('Org agenda a')
vim.wait(2000, function()
  return vim.bo.filetype == 'orgagenda'
end)
assert_eq(vim.bo.filetype, 'orgagenda', 'the agenda buffer is open')

-- Put the cursor inside the [[standup]] link of the agenda line.
local agenda_win = vim.api.nvim_get_current_win()
local col
for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  local start = line:find('[[standup]]', 1, true)
  if start then
    col = start + 2
    vim.api.nvim_win_set_cursor(0, { i, col })
    break
  end
end
assert(col, 'the agenda renders the wikilink as plain text')

-- The agenda sits below an existing window: gd reuses that window.
local top_win = vim.fn.win_getid(vim.fn.winnr('k'))
assert(top_win ~= agenda_win, 'the agenda opened below another window')
vim.cmd('normal gd')
assert_eq(vim.api.nvim_get_current_win(), top_win, 'gd reuses the window above the agenda')
assert_eq(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p'), work .. '/standup.md', 'gd opens the work vault note')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 2, 'no extra window is created')

-- Agenda alone in the tab: gd splits a window above it and opens the note there.
vim.api.nvim_win_close(top_win, true)
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 1, 'only the agenda is left')
vim.cmd('normal gd')
assert_eq(
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p'),
  work .. '/standup.md',
  'gd opens the note after splitting'
)
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 2, 'gd split a second window')
assert(
  vim.api.nvim_win_get_position(0)[1] < vim.api.nvim_win_get_position(agenda_win)[1],
  'the note opens above the agenda'
)

-- Off a link, gd falls through to orgmode's open-at-point (which only echoes an
-- error here) and leaves the layout alone.
vim.api.nvim_set_current_win(agenda_win)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('silent! normal gd')
assert_eq(vim.api.nvim_get_current_win(), agenda_win, 'gd without a link stays in the agenda')

print('OK')
