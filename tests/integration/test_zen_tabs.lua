-- Integration test (real nvim, headless): zen mode is tab-exclusive -- every
-- tab page owns its own zen window, and the toggle key only ever acts on the
-- zen window of the current tab.
--
-- `Snacks.zen` keeps its window in a module singleton and closes zen when
-- another window is entered (a tab switch enters one), so lib.zen owns the
-- per-tab registry and re-installs a tab-aware WinEnter close.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local cwd = vim.fn.getcwd()
local snacks_dir = vim.fn.expand('~/.local/share/nvim/lazy/snacks.nvim')
if vim.fn.isdirectory(snacks_dir) == 0 then
  print('SKIP: snacks.nvim not installed')
  os.exit(0)
end

vim.opt.rtp:prepend(cwd)
vim.opt.rtp:prepend(snacks_dir)
package.path = cwd .. '/lua/?.lua;' .. package.path

require('snacks').setup({})
_G.lib = require('lib')

local function assert_true(cond, msg)
  if not cond then
    error(msg or 'assert_true failed', 2)
  end
end

---@param opts? snacks.zen.Config
local function toggle(opts)
  lib.zen.toggle(vim.tbl_extend('force', { win = { style = { width = 40, height = 0 } } }, opts or {}))
end

local function tabid()
  return vim.api.nvim_get_current_tabpage()
end

-- tab 1: open zen
local t1 = tabid()
local opened, closed = 0, 0
local hooks = {
  on_open = function()
    opened = opened + 1
  end,
  on_close = function()
    closed = closed + 1
  end,
}
toggle(hooks)
local z1 = lib.zen.get()
assert_true(z1 ~= nil, 'tab1: zen did not open')
assert_true(vim.api.nvim_win_get_tabpage(z1.win) == t1, 'tab1: zen window is not in its own tab')
assert_true(opened == 1, 'tab1: on_open not called')

-- switching tabs keeps it open
vim.cmd('tabnew')
local t2 = tabid()
assert_true(t1 ~= t2, 'tabnew did not create a tab')
assert_true(lib.zen.get() == nil, 'tab2: has no zen of its own')
assert_true(z1:win_valid(), 'tab2: zen of tab1 was closed by the tab switch')

-- tab 2 opens its own zen; tab 1's must survive
toggle(hooks)
local z2 = lib.zen.get()
assert_true(z2 ~= nil and z2 ~= z1, 'tab2: zen did not open')
assert_true(vim.api.nvim_win_get_tabpage(z2.win) == t2, 'tab2: zen window is not in its own tab')
assert_true(z1:win_valid(), 'tab2: zen of tab1 was closed when tab2 opened zen')
assert_true(lib.zen.any(), 'any() is false with two zens open')

-- returning to tab 1 finds its own zen focused
vim.cmd('tabprevious')
assert_true(tabid() == t1, 'tabprevious did not go to tab1')
assert_true(lib.zen.get() == z1, 'tab1: get() does not return its own zen')
assert_true(vim.api.nvim_get_current_win() == z1.win, 'tab1: zen window is not the current window')

-- toggling tab 1 closes only tab 1's zen
toggle(hooks)
assert_true(lib.zen.get(t1) == nil, 'tab1: zen did not close')
assert_true(z2:win_valid(), 'tab1: closing zen in tab1 closed tab2 zen')
assert_true(closed == 1, 'tab1: on_close not called once')

-- a window entered in the same tab still closes zen
toggle(hooks)
assert_true(lib.zen.get(t1) ~= nil, 'tab1: zen did not reopen')
vim.cmd('vsplit')
vim.wait(200, function()
  return lib.zen.get(t1) == nil
end)
assert_true(lib.zen.get(t1) == nil, 'tab1: zen stayed open after a split in the same tab')

-- closing the owning tab forgets its zen
vim.cmd('tabnext')
assert_true(tabid() == t2, 'tabnext did not go to tab2')
assert_true(lib.zen.get(t2) == z2, 'tab2: get() does not return its own zen')
vim.cmd('tabclose')
assert_true(not vim.api.nvim_tabpage_is_valid(t2), 'tab2: tab was not closed')
assert_true(lib.zen.get(t2) == nil, 'tab2: registry kept a zen after its tab was closed')
assert_true(not lib.zen.any(), 'any() is true with every zen tab closed')
assert_true(opened == 3, 'on_open not called for every zen opened')
assert_true(closed == 3, 'tab2: on_close not called on tab close')

print('OK')
