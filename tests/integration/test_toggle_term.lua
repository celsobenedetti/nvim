-- Integration test (real nvim, headless): the toggle terminal is
-- tab-exclusive -- every tab page owns its own terminal, and the toggle key
-- only ever acts on the terminal of the current tab.
--
-- The tab owning a terminal is tracked in state.toggle_term_bufs (tabpage id
-- -> buffer); the window showing it is found per tab, so a terminal moved to
-- another tab (<C-w>T) leaves its old tab without one.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local script = debug.getinfo(1, 'S').source:sub(2)
local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
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

-- Globals after/plugin/terminal.lua expects from the live config.
_G.state = {
  toggle_term_bufs = {},
  insert_when_entering_terminal = true,
  autoinsert_on_term = true,
}
_G.config = {
  keys = { ['<C-/>'] = '<C-_>' },
  agents = {},
}
_G.lib = {
  term = require('lib.term'),
  buffers = {
    get_valid_bufs = function()
      return {}
    end,
  },
}
_G.Snacks = { notify = { info = function() end, warn = function() end } }

vim.cmd('luafile ' .. cwd .. '/after/plugin/terminal.lua')

--- Run the toggle terminal keymap.
local function toggle()
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.desc == 'Toggle terminal' then
      map.callback()
      return
    end
  end
  error('toggle terminal keymap not found')
end

--- Does a tab page show a buffer?
---@param tabid integer
---@param bufnr integer
---@return boolean
local function tab_shows(tabid, bufnr)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return true
    end
  end
  return false
end

--- Focus the window of a tab page showing a buffer.
---@param tabid integer
---@param bufnr integer
local function focus(tabid, bufnr)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_set_current_tabpage(tabid)
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  error('buffer not shown in the tab')
end

--- Focus the window of a tab page that shows another buffer.
---@param tabid integer
---@param bufnr integer
local function focus_other(tabid, bufnr)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    if vim.api.nvim_win_get_buf(win) ~= bufnr then
      vim.api.nvim_set_current_tabpage(tabid)
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  error('no other window in the tab')
end

-- ================================================================
-- Tab 1 opens its own terminal.
local tab1 = vim.api.nvim_get_current_tabpage()
toggle()
local term1 = state.toggle_term_bufs[tab1]
assert_true(term1 ~= nil, 'tab 1 got a toggle terminal')
assert_eq(vim.bo[term1].buftype, 'terminal', 'the toggle terminal is a terminal buffer')
assert_true(tab_shows(tab1, term1), 'tab 1 shows its toggle terminal')

-- ================================================================
-- Tab 2 gets a terminal of its own, tab 1 keeps hers.
vim.cmd('tabnew')
local tab2 = vim.api.nvim_get_current_tabpage()
toggle()
local term2 = state.toggle_term_bufs[tab2]
assert_true(term2 ~= nil, 'tab 2 got a toggle terminal')
assert_true(term2 ~= term1, 'the tabs have different terminals')
assert_eq(state.toggle_term_bufs[tab1], term1, 'tab 1 kept its terminal')
assert_true(tab_shows(tab1, term1), 'tab 1 still shows its terminal')
assert_true(not tab_shows(tab2, term1), 'tab 2 does not show the terminal of tab 1')

-- ================================================================
-- The toggle key acts on the current tab only.
toggle()
assert_true(not tab_shows(tab2, term2), 'tab 2 closed its terminal')
assert_true(tab_shows(tab1, term1), "tab 1's terminal is untouched")
assert_eq(state.toggle_term_bufs[tab2], term2, 'tab 2 still owns the hidden terminal')

-- ...and reopens the very same one.
toggle()
assert_true(tab_shows(tab2, term2), 'tab 2 reopened its terminal')
assert_eq(state.toggle_term_bufs[tab2], term2, 'the same terminal came back')
assert_true(tab_shows(tab1, term1), "tab 1's terminal is still open")

-- ================================================================
-- Back in tab 1: its toggle closes tab 1's terminal, not tab 2's.
vim.api.nvim_set_current_tabpage(tab1)
toggle()
assert_true(not tab_shows(tab1, term1), 'tab 1 closed its terminal')
assert_true(tab_shows(tab2, term2), "tab 2's terminal is untouched")
toggle()
assert_true(tab_shows(tab1, term1), 'tab 1 reopened its terminal')

-- ================================================================
-- Moving a terminal to another tab takes it away from the tab that owned it.
focus(tab1, term1)
vim.cmd('wincmd T')
-- the move is only complete when the command ends
vim.wait(200, function()
  return false
end)
local tab3 = vim.api.nvim_get_current_tabpage()
assert_true(tab3 ~= tab1 and tab3 ~= tab2, 'the terminal moved to a new tab')
assert_true(tab_shows(tab3, term1), 'the new tab shows the terminal')
assert_eq(state.toggle_term_bufs[tab1], nil, 'tab 1 forgot the moved terminal')
assert_eq(state.toggle_term_bufs[tab3], nil, 'the new tab did not adopt it')

-- the tab that lost it opens a fresh terminal on the next toggle
vim.api.nvim_set_current_tabpage(tab1)
toggle()
local term1b = state.toggle_term_bufs[tab1]
assert_true(term1b ~= nil and term1b ~= term1, 'tab 1 opened a fresh terminal')
assert_true(tab_shows(tab1, term1b), 'tab 1 shows the fresh terminal')

-- ================================================================
-- A resize in one tab leaves the terminals of the other tabs alone: the
-- docked check reads the layout of every tab, the current one or not.
vim.api.nvim_set_current_tabpage(tab2)
focus_other(tab2, term2)
vim.cmd('vsplit')
vim.api.nvim_exec_autocmds('WinResized', {})
assert_eq(state.toggle_term_bufs[tab1], term1b, "tab 1's terminal survived the resize in tab 2")
assert_eq(state.toggle_term_bufs[tab2], term2, "tab 2's terminal survived the resize")
assert_true(tab_shows(tab1, term1b), 'tab 1 still shows its terminal')
assert_true(tab_shows(tab2, term2), 'tab 2 still shows its terminal')

os.exit(0)
