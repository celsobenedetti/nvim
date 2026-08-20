--- Tests for lib.buffers write-all-and-quit helpers
--- Run with: luajit tests/lib/test_buffers.lua
---
--- Mocks the neovim api the module depends on.

package.path = './lua/?.lua;' .. package.path

local mock = {}

function mock.setup(tbl)
  for k, v in pairs(tbl) do
    rawset(_G, k, v)
  end
end

function mock.teardown(keys)
  for _, k in ipairs(keys) do
    rawset(_G, k, nil)
  end
end

local tests_run = 0
local tests_passed = 0

local function assert_eq(got, expected, msg)
  tests_run = tests_run + 1
  if got == expected then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %q\n  got:      %q\n', msg, expected, got))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

-- Mutable buffer state the mock reads from.
local bufs = {}
local buf_state = {}
local writes = {}
local cmd_calls = {}
local notify_calls = {}
local qf_calls = {}

-- Window/tab state the mock reads from (winid -> { tab, buf }).
local win_state = {}
local current_tab = 1
local set_current_win_calls = {}
local set_current_tab_calls = {}
local set_current_buf_calls = {}

local vim_mock = {
  fn = {
    setqflist = function(items, action, opts)
      qf_calls[#qf_calls + 1] = { items = items, action = action, opts = opts }
    end,
    bufwinid = function(buf)
      for winid, st in pairs(win_state) do
        if st.buf == buf and st.tab == current_tab then
          return winid
        end
      end
      return -1
    end,
    win_findbuf = function(buf)
      local found = {}
      for winid, st in pairs(win_state) do
        if st.buf == buf then
          found[#found + 1] = winid
        end
      end
      table.sort(found)
      return found
    end,
  },
  api = {
    nvim_list_bufs = function()
      return bufs
    end,
    nvim_buf_is_valid = function(id)
      return buf_state[id] and buf_state[id].valid or false
    end,
    nvim_buf_is_loaded = function(id)
      return buf_state[id] and buf_state[id].loaded or false
    end,
    nvim_buf_get_name = function(id)
      return buf_state[id] and buf_state[id].name or ''
    end,
    nvim_get_option_value = function(name, opts)
      local id = opts.buf
      return buf_state[id] and buf_state[id][name]
    end,
    nvim_buf_call = function(id, fn)
      if buf_state[id].write_error then
        error(buf_state[id].write_error, 0)
      end
      writes[#writes + 1] = id
      return fn()
    end,
    nvim_win_get_tabpage = function(winid)
      return win_state[winid].tab
    end,
    nvim_set_current_win = function(winid)
      current_tab = win_state[winid].tab
      set_current_win_calls[#set_current_win_calls + 1] = winid
    end,
    nvim_set_current_tabpage = function(tab)
      current_tab = tab
      set_current_tab_calls[#set_current_tab_calls + 1] = tab
    end,
    nvim_set_current_buf = function(buf)
      set_current_buf_calls[#set_current_buf_calls + 1] = buf
    end,
  },
  cmd = setmetatable({}, {
    __call = function(_, command)
      cmd_calls[#cmd_calls + 1] = command
    end,
    __index = function(_, command)
      return function()
        cmd_calls[#cmd_calls + 1] = command
      end
    end,
  }),
  notify = function(msg, level, opts)
    notify_calls[#notify_calls + 1] = { msg = msg, level = level, opts = opts }
  end,
  log = {
    levels = { ERROR = 'ERROR' },
  },
}

mock.setup({
  vim = vim_mock,
  lib = {
    overseer = {
      get_active_tasks = function()
        return {}
      end,
    },
  },
})

local function reset()
  bufs = {}
  buf_state = {}
  writes = {}
  cmd_calls = {}
  notify_calls = {}
  qf_calls = {}
  win_state = {}
  current_tab = 1
  set_current_win_calls = {}
  set_current_tab_calls = {}
  set_current_buf_calls = {}
end

local function add_buf(id, overrides)
  table.insert(bufs, id)
  buf_state[id] = {
    name = '',
    buftype = '',
    modifiable = true,
    modified = true,
    valid = true,
    loaded = true,
    write_error = nil,
  }
  for k, v in pairs(overrides or {}) do
    buf_state[id][k] = v
  end
end

local function count(buf, list)
  local n = 0
  for _, v in ipairs(list) do
    if v == buf then
      n = n + 1
    end
  end
  return n
end

local function last_cmd()
  return cmd_calls[#cmd_calls]
end

local function quit_issued()
  for _, v in ipairs(cmd_calls) do
    if v == 'qa!' then
      return true
    end
  end
  return false
end

local buffers = require('lib.buffers')

-- ============================================================
describe('lib.buffers.wqa: writes modified named file buffers and quits')

reset()
add_buf(1, { name = '/tmp/a.txt', modified = true })
add_buf(2, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 1, 'writes buffer 1')
assert_eq(count(2, writes), 1, 'writes buffer 2')
assert_eq(last_cmd(), 'qa!', 'quits after all writes')
assert_eq(#notify_calls, 0, 'no error notification')

-- ============================================================
describe('lib.buffers.wqa: skips buffers that cannot be written')

reset()
add_buf(1, { name = '/tmp/a.txt', modified = true })
add_buf(2, { name = '', modified = true })
add_buf(3, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 1, 'writes named buffer')
assert_eq(count(2, writes), 0, 'skips unnamed buffer')
assert_eq(count(3, writes), 1, 'writes second named buffer')
assert_eq(last_cmd(), 'qa!', 'quits')

-- unmodified buffer is not written
reset()
add_buf(1, { name = '/tmp/a.txt', modified = false })
add_buf(2, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 0, 'skips unmodified buffer')
assert_eq(count(2, writes), 1, 'writes modified buffer')
assert_eq(last_cmd(), 'qa!', 'quits')

-- special buftype is not written
reset()
add_buf(1, { name = '[terminal]', buftype = 'terminal', modified = true })
add_buf(2, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 0, 'skips terminal buffer')
assert_eq(count(2, writes), 1, 'writes file buffer')
assert_eq(last_cmd(), 'qa!', 'quits')

-- non-modifiable buffer is not written
reset()
add_buf(1, { name = '/tmp/a.txt', modifiable = false, modified = true })
add_buf(2, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 0, 'skips nomodifiable buffer')
assert_eq(count(2, writes), 1, 'writes modifiable buffer')
assert_eq(last_cmd(), 'qa!', 'quits')

-- unloaded / invalid buffers are not touched
reset()
add_buf(1, { name = '/tmp/a.txt', modified = true })
add_buf(2, { name = '/tmp/b.txt', loaded = false, modified = true })
add_buf(3, { name = '/tmp/c.txt', valid = false, modified = true })
buffers.wqa()
assert_eq(count(1, writes), 1, 'writes valid loaded buffer')
assert_eq(count(2, writes), 0, 'skips unloaded buffer')
assert_eq(count(3, writes), 0, 'skips invalid buffer')
assert_eq(last_cmd(), 'qa!', 'quits')

-- ============================================================
describe('lib.buffers.wqa: aborts quit and notifies on write error')

reset()
add_buf(1, { name = '/tmp/a.txt', write_error = "Vim(write):E212: Can't open file for writing" })
add_buf(2, { name = '/tmp/b.txt', modified = true })
buffers.wqa()
assert_eq(count(1, writes), 0, 'failed buffer not recorded as written')
assert_eq(count(2, writes), 1, 'still writes the good buffer')
assert_eq(quit_issued(), false, 'does not quit')
assert_eq(#notify_calls, 1, 'notifies about the failure')
assert_eq(notify_calls[1].msg, "/tmp/a.txt: E212: Can't open file for writing", 'extracts message and prefixes name')
assert_eq(notify_calls[1].level, 'ERROR', 'error level')
assert_eq(notify_calls[1].opts.title, 'wqa', 'notification title')

-- multi-line error keeps only the first line
reset()
add_buf(1, { name = '/tmp/a.txt', write_error = 'Vim(write):E212: first line\nsecond line' })
buffers.wqa()
assert_eq(#notify_calls, 1, 'notifies')
assert_eq(notify_calls[1].msg, '/tmp/a.txt: E212: first line', 'strips to first line')

-- error without Vim(...) prefix keeps the whole first line
reset()
add_buf(1, { name = '/tmp/a.txt', write_error = 'something bad happened' })
buffers.wqa()
assert_eq(notify_calls[1].msg, '/tmp/a.txt: something bad happened', 'keeps raw message')

-- multiple failures are joined
reset()
add_buf(1, { name = '/tmp/a.txt', write_error = 'Vim(write):E212: first' })
add_buf(2, { name = '/tmp/b.txt', write_error = 'Vim(write):E212: second' })
buffers.wqa()
assert_eq(notify_calls[1].msg, '/tmp/a.txt: E212: first\n/tmp/b.txt: E212: second', 'joins errors with newline')
assert_eq(quit_issued(), false, 'does not quit')

-- ============================================================
describe('lib.buffers.to_quickfix: sends named loaded file buffers to the quickfix list')

reset()
add_buf(1, { name = '/tmp/a.txt' })
add_buf(2, { name = '/tmp/b.txt' })
buffers.to_quickfix()
assert_eq(#qf_calls, 1, 'calls setqflist once')
assert_eq(qf_calls[1].action, ' ', 'replaces the quickfix list')
assert_eq(qf_calls[1].opts.title, 'Open buffers', 'sets a title')
assert_eq(qf_calls[1].opts.items[1].filename, '/tmp/a.txt', 'first buffer filename')
assert_eq(qf_calls[1].opts.items[1].lnum, 1, 'first buffer lnum')
assert_eq(qf_calls[1].opts.items[2].filename, '/tmp/b.txt', 'second buffer filename')
assert_eq(last_cmd(), 'copen', 'opens the quickfix window')

-- unnamed, unloaded, and nofile buffers are skipped
reset()
add_buf(1, { name = '/tmp/a.txt' })
add_buf(2, { name = '' })
add_buf(3, { name = '/tmp/c.txt', loaded = false })
add_buf(4, { name = '/tmp/d.txt', buftype = 'nofile' })
buffers.to_quickfix()
assert_eq(#qf_calls[1].opts.items, 1, 'only the valid named loaded file buffer is included')
assert_eq(qf_calls[1].opts.items[1].filename, '/tmp/a.txt', 'keeps the file buffer')
assert_eq(last_cmd(), 'copen', 'opens the quickfix window')

-- no buffers: opens an empty quickfix list
reset()
buffers.to_quickfix()
assert_eq(#qf_calls[1].opts.items, 0, 'empty items list')
assert_eq(last_cmd(), 'copen', 'still opens the quickfix window')

-- ============================================================
describe('lib.buffers.focus: focuses the buffer in the right tab page')

local function add_win(winid, tab, buf)
  win_state[winid] = { tab = tab, buf = buf }
end

-- rendered in the current tab: switch to that window, no tab change
reset()
add_win(3, 1, 10)
buffers.focus(10)
assert_eq(#set_current_win_calls, 1, 'sets the current window')
assert_eq(set_current_win_calls[1], 3, 'to the window showing the buffer')
assert_eq(#set_current_tab_calls, 0, 'does not switch tabs')
assert_eq(#set_current_buf_calls, 0, 'does not set current buffer')

-- rendered in another tab: switch to that tab and that window
reset()
add_win(5, 2, 10)
buffers.focus(10)
assert_eq(#set_current_tab_calls, 1, 'switches tabs')
assert_eq(set_current_tab_calls[1], 2, 'to the tab hosting the buffer')
assert_eq(#set_current_win_calls, 1, 'sets the current window')
assert_eq(set_current_win_calls[1], 5, 'to the window showing the buffer')
assert_eq(#set_current_buf_calls, 0, 'does not set current buffer')

-- rendered in the current tab takes precedence over another tab
reset()
add_win(5, 2, 10)
add_win(7, 1, 10)
buffers.focus(10)
assert_eq(#set_current_tab_calls, 0, 'does not switch tabs')
assert_eq(set_current_win_calls[1], 7, 'focuses the window in the current tab')

-- not rendered anywhere: set current buffer (opens a window in current tab)
reset()
buffers.focus(10)
assert_eq(#set_current_buf_calls, 1, 'sets the current buffer')
assert_eq(set_current_buf_calls[1], 10, 'to the requested buffer')
assert_eq(#set_current_tab_calls, 0, 'does not switch tabs')
assert_eq(#set_current_win_calls, 0, 'does not set current window')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
