--- Tests for after/plugin/pi.lua: recognising terminals that run pi, and the
--- insert-mode exemption it registers with lib.term. The output-following
--- autocmd needs real windows and a real terminal job, so it is covered by
--- tests/integration/test_terminal_follow.lua instead.
--- Run with: luajit tests/plugin/test_pi.lua

package.path = './lua/?.lua;' .. package.path

local tests_run = 0
local tests_passed = 0

local function assert_eq(got, expected, msg)
  tests_run = tests_run + 1
  if got == expected then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %s\n  got:      %s\n', msg, tostring(expected), tostring(got)))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

local current_buf = 1
local buf_types = {}
local buf_names = {}
-- process tree of the mocked terminals: bufnr -> job pid, pid -> comm/children
local buf_pids = {}
local proc_names = {}
local proc_children = {}
local clock = 0
local cmds = {}
local autocmds = {}

local vim_mock = {
  api = {
    nvim_get_current_buf = function()
      return current_buf
    end,
    nvim_get_current_win = function()
      return 1000
    end,
    nvim_win_get_config = function()
      return { relative = '' }
    end,
    nvim_buf_get_name = function(buf)
      return buf_names[buf] or ''
    end,
    nvim_get_proc_children = function(pid)
      return proc_children[pid] or {}
    end,
    nvim_create_augroup = function()
      return 1
    end,
    nvim_create_autocmd = function(event, opts)
      autocmds[event] = opts
    end,
  },
  bo = setmetatable({}, {
    __index = function(_, buf)
      return { buftype = buf_types[buf] or '', channel = buf_pids[buf] and buf or 0 }
    end,
  }),
  fn = {
    jobpid = function(channel)
      local pid = buf_pids[channel]
      if not pid then
        error('E900: Invalid channel id')
      end
      return pid
    end,
    -- stands in for reading /proc/<pid>/comm, which throws when pid is gone
    readfile = function(path)
      local pid = tonumber(path:match('/proc/(%d+)/comm'))
      local name = proc_names[pid]
      if not name then
        error("E484: Can't open file " .. path)
      end
      return { name }
    end,
  },
  fs = {
    basename = function(path)
      return path:match('[^/]*$')
    end,
  },
  uv = {
    now = function()
      return clock
    end,
  },
  cmd = function(cmd)
    cmds[#cmds + 1] = cmd
  end,
}

rawset(_G, 'vim', vim_mock)
rawset(_G, 'state', { insert_when_entering_terminal = true })
rawset(_G, 'lib', { term = require('lib.term') })

-- Load the plugin file under test the way nvim sources it: for its side effects
-- (state.pi, the startinsert exemption, the WinLeave autocmd).
assert(loadfile('./after/plugin/pi.lua'))()
local is_running = state.pi.is_running

local function setup()
  current_buf = 1
  buf_types = {}
  buf_names = {}
  buf_pids = {}
  proc_names = {}
  proc_children = {}
  cmds = {}
  -- past any cached detection from an earlier case (CACHE_MS = 500)
  clock = clock + 10000
end

describe('is_running: the job command says pi')

-- The state at TermOpen: the job command is pi, but the job process is still
-- the shell about to exec it.
setup()
current_buf = 7
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:pi'
buf_pids[7] = 100
proc_names[100] = 'bash'
assert_eq(is_running(), true, 'is_running() reads the current buffer')
assert_eq(is_running(7), true, 'job command `pi` counts before the exec lands')
buf_names[7] = 'term://~/projects/nvim//100:/home/me/.local/bin/pi --resume'
assert_eq(is_running(7), true, 'detected via an absolute command path with args')
buf_names[7] = 'term://~/projects/nvim//100:pip install pi'
assert_eq(is_running(7), false, 'a command merely starting with pi is not pi')
buf_names[7] = 'term://~/projects/nvim//100:/usr/bin/bash'
assert_eq(is_running(7), false, 'shell job command is not pi')

describe('is_running: pi in the job process tree')

-- `:term pi` once it has exec'd: pi is the job process itself
setup()
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(is_running(7), true, 'pi as the job process is detected')

-- pi started by hand in a shell terminal: one level below the job process
setup()
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'pi'
proc_children[100] = { 200 }
assert_eq(is_running(7), true, 'pi as a child of the shell is detected')

-- a wrapper between the shell and pi (mise exec, npx): two levels down
setup()
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'mise'
proc_names[300] = 'pi'
proc_children[100] = { 200 }
proc_children[200] = { 300 }
assert_eq(is_running(7), true, 'pi below a wrapper process is detected')

-- deeper than SEARCH_DEPTH: not detected
setup()
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'bash'
proc_names[300] = 'mise'
proc_names[400] = 'pi'
proc_children[100] = { 200 }
proc_children[200] = { 300 }
proc_children[300] = { 400 }
assert_eq(is_running(7), false, 'pi beyond the search depth is not detected')

describe('is_running: nothing running pi')

setup()
buf_types[7] = 'terminal'
buf_types[8] = ''
buf_pids[7] = 100
buf_pids[8] = 101
proc_names[100] = 'bash'
proc_names[201] = 'rg'
proc_children[100] = { 201 }
proc_names[101] = 'pi'
assert_eq(is_running(7), false, 'shell terminal without pi is not pi')
assert_eq(is_running(8), false, 'non-terminal buffer is never pi, whatever it runs')

setup()
buf_types[7] = 'terminal'
assert_eq(is_running(7), false, 'terminal with no live channel is not pi')
buf_pids[7] = 100
assert_eq(is_running(7), false, 'job pid that no longer exists is not pi')

describe('is_running: caching')

setup()
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(is_running(7), true, 'pi detected before it exits')
proc_names[100] = nil
assert_eq(is_running(7), true, 'cached within the TTL even though pi exited')
clock = clock + 500
assert_eq(is_running(7), false, 'rescanned after the TTL: pi is gone')

describe('startinsert exemption')

-- lib.term.startinsert consults the exemption pi.lua registered at load.
setup()
current_buf = 7
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
lib.term.startinsert()
assert_eq(cmds[1], nil, 'no startinsert in a terminal running pi')

setup()
current_buf = 7
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:pi'
buf_pids[7] = 100
proc_names[100] = 'bash'
lib.term.startinsert()
assert_eq(cmds[1], nil, 'no startinsert in a pi terminal that is still starting')

setup()
current_buf = 7
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:/usr/bin/bash'
buf_pids[7] = 100
proc_names[100] = 'bash'
lib.term.startinsert()
assert_eq(cmds[1], 'startinsert', 'startinsert in a terminal not running pi')

describe('autocmds')

assert_eq(type(autocmds.WinLeave), 'table', 'a WinLeave handler is registered for the follow flag')

io.write(string.format('\n\n%d/%d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
