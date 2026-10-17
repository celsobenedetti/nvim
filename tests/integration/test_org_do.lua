-- Integration test (real nvim, headless): :OrgDo reads the heading under the
-- cursor and opens a pi agent in a vertical split on it, writing modified org
-- buffers first so pi reads current contents. :OrgDoSearch's todo filter is
-- exercised through the loader it uses: active TODO states kept, DONE and plain
-- headings dropped.
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

-- A stub `pi` that records its arguments instead of starting an agent, and
-- stays alive so the terminal buffer does not close.
local root = vim.fn.tempname()
local bin, org = root .. '/bin', root .. '/org'
vim.fn.mkdir(bin, 'p')
vim.fn.mkdir(org, 'p')
local recorded = root .. '/args'
vim.fn.writefile({ '#!/bin/sh', "printf '%s\\n' \"$@\" > " .. recorded, 'sleep 30' }, bin .. '/pi')
vim.fn.setfperm(bin .. '/pi', 'rwxr-xr-x')
vim.env.PATH = bin .. ':' .. vim.env.PATH

local file = org .. '/tasks.org'
vim.fn.writefile({ '* TODO active', '  body', '* DONE finished', '* plain' }, file)

require('orgmode').setup({ org_agenda_files = { org .. '/*.org' } })
vim.cmd.edit(file)
assert_eq(vim.bo.filetype, 'org', 'the fixture opens as an org buffer')

-- The todo filter keeps only active TODO states.
local records = lib.org_fzf._load_headlines({ todo_only = true })
local titles = vim.tbl_map(function(r)
  return r.title
end, records)
assert_eq(vim.inspect(titles), vim.inspect({ 'active' }), 'only active TODO headings are offered')

vim.cmd('luafile ' .. cwd .. '/after/plugin/pi.lua')
lib.org_do.setup_commands()

-- :OrgDo saves the dirty buffer, then launches pi on the heading under the cursor.
vim.api.nvim_buf_set_lines(0, 1, 2, false, { '  changed' })
assert_eq(vim.bo.modified, true, 'the buffer is dirty before launch')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('OrgDo')

assert(vim.wait(5000, function()
  return vim.fn.filereadable(recorded) == 1
end), 'the stub pi was launched')
assert_eq(vim.fn.readfile(file)[2], '  changed', 'the org buffer was written before launch')
local args = vim.fn.readfile(recorded)
assert_eq(args[1], '--name', 'the session is named')
assert_eq(args[2], 'active', 'the session name is the heading title')
assert_eq(args[3], 'task: ' .. file .. ':1:2', 'the message is the heading reference')
assert_eq(#vim.api.nvim_tabpage_list_wins(0), 2, 'pi opened in a vertical split')

print('OK')
