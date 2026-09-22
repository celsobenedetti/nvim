--- Tests for lib.term.was_following terminal tailing decision.
--- Run with: luajit tests/lib/test_term.lua

package.path = './lua/?.lua;' .. package.path

local lib_term = require('lib.term')

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

describe('was_following')
-- Leaving from terminal-mode always counts as following: the cursor is pinned
-- to the terminal's own cursor and cannot be scrolled, wherever it happens to be.
assert_eq(lib_term.was_following(1, 100, 't'), true, 'terminal-mode leave follows even with cursor at top')
assert_eq(lib_term.was_following(38, 41, 't'), true, 'terminal-mode leave follows with pi-style parked cursor')
-- Normal-mode leave: cursor exactly on the last line is following.
assert_eq(lib_term.was_following(100, 100, 'n'), true, 'cursor on last line follows')
-- TUIs (pi) park the cursor a few lines above the end; still following.
assert_eq(lib_term.was_following(97, 100, 'n'), true, 'cursor near end follows')
-- Scrolled up to read history: not following.
assert_eq(lib_term.was_following(50, 100, 'n'), false, 'cursor mid-buffer does not follow')
assert_eq(lib_term.was_following(1, 100, 'n'), false, 'cursor at top does not follow')

-- ============================================================
describe('agent terminal helpers')

local current_buf = 1
local buf_types = {}
local agent_bufs = {}
-- process tree of the mocked terminals: bufnr -> job pid, pid -> comm/children
local buf_pids = {}
local buf_names = {}
local proc_names = {}
local proc_children = {}
local clock = 0
local cmds = {}

local vim_mock = {
  api = {
    nvim_get_current_buf = function()
      return current_buf
    end,
    nvim_get_proc_children = function(pid)
      return proc_children[pid] or {}
    end,
    nvim_buf_get_name = function(buf)
      return buf_names[buf] or ''
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
  uv = {
    now = function()
      return clock
    end,
  },
  fs = {
    basename = function(path)
      return path:match('[^/]*$')
    end,
  },
  cmd = function(cmd)
    cmds[#cmds + 1] = cmd
  end,
}

---@param with_agents boolean whether state.agents is populated
local function setup(with_agents)
  current_buf = 1
  buf_types = {}
  agent_bufs = {}
  buf_pids = {}
  buf_names = {}
  proc_names = {}
  proc_children = {}
  cmds = {}
  -- past any cached pi detection from an earlier case (PI_CACHE_MS = 500)
  clock = clock + 10000
  rawset(_G, 'vim', vim_mock)
  rawset(_G, 'state', with_agents and {
    agents = {
      get_agent_bufnr = function(agent)
        return agent_bufs[agent] or 0
      end,
      bufnr = agent_bufs,
    },
  } or {})
end

-- without state.agents nothing is an agent terminal
setup(false)
assert_eq(lib_term.is_agent(42), false, 'no state.agents -> is_agent false')
assert_eq(lib_term.is_claude(42), false, 'no state.agents -> is_claude false')
assert_eq(lib_term.is_pi_agent(42), false, 'no state.agents -> is_pi_agent false')

-- a non-terminal buffer is never an agent terminal
setup(true)
buf_types[7] = ''
agent_bufs.claude = 7
assert_eq(lib_term.is_agent(7), false, 'non-terminal buffer not an agent')
assert_eq(lib_term.is_claude(7), false, 'non-terminal buffer not claude')

-- claude terminal registered in state.agents
setup(true)
current_buf = 42
buf_types[42] = 'terminal'
agent_bufs.claude = 42
assert_eq(lib_term.is_claude(), true, 'is_claude() detects current buffer')
assert_eq(lib_term.is_claude(42), true, 'is_claude(bufnr) detects explicit buffer')
assert_eq(lib_term.is_agent(42), true, 'is_agent catches claude buffer')
assert_eq(lib_term.is_opencode(42), false, 'claude buffer is not opencode')
assert_eq(lib_term.is_pi_agent(42), false, 'claude buffer is not the pi agent')
assert_eq(lib_term.is_agent(7), false, 'other terminal buffer not an agent')

-- pi terminal registered alongside claude
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_types[42] = 'terminal'
agent_bufs.claude = 42
agent_bufs.pi = 7
assert_eq(lib_term.is_pi_agent(), true, 'is_pi_agent() detects current buffer')
assert_eq(lib_term.is_pi_agent(7), true, 'is_pi_agent(bufnr) detects explicit buffer')
assert_eq(lib_term.is_agent(7), true, 'is_agent catches pi buffer')
assert_eq(lib_term.is_agent(42), true, 'is_agent catches claude buffer too')
assert_eq(lib_term.is_claude(7), false, 'pi buffer is not claude')

-- agent bufnr cleared (TermClose sets it to 0) -> no longer detected
setup(true)
current_buf = 42
buf_types[42] = 'terminal'
agent_bufs.claude = 0
assert_eq(lib_term.is_claude(42), false, 'cleared agent bufnr not detected')
assert_eq(lib_term.is_agent(42), false, 'cleared agent bufnr not an agent')

-- ============================================================
describe('is_pi: any terminal running a pi process')

-- `:term pi` — pi is the job process itself
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(lib_term.is_pi(), true, 'is_pi() detects pi as the job process')
assert_eq(lib_term.is_pi(7), true, 'is_pi(bufnr) detects pi as the job process')

-- The job command names pi, but it has not exec'd yet (the state at TermOpen:
-- the job process is still the shell about to become pi).
setup(true)
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:pi'
buf_pids[7] = 100
proc_names[100] = 'bash'
assert_eq(lib_term.is_pi(7), true, 'job command `pi` counts before the exec lands')
buf_names[7] = 'term://~/projects/nvim//100:/home/me/.local/bin/pi --resume'
assert_eq(lib_term.is_pi(7), true, 'job command detected via an absolute path with args')
buf_names[7] = 'term://~/projects/nvim//100:pip install pi'
assert_eq(lib_term.is_pi(7), false, 'a command merely starting with pi is not pi')
buf_names[7] = 'term://~/projects/nvim//100:/usr/bin/bash'
assert_eq(lib_term.is_pi(7), false, 'shell job command is not pi')

-- pi started by hand inside a shell terminal: one level below the job process,
-- and not registered with state.agents at all
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'pi'
proc_children[100] = { 200 }
assert_eq(lib_term.is_pi(7), true, 'pi as a child of the shell is detected')
assert_eq(lib_term.is_pi_agent(7), false, 'a hand-started pi is not the pi agent')

-- wrapper between the shell and pi (mise exec, npx): two levels down
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'mise'
proc_names[300] = 'pi'
proc_children[100] = { 200 }
proc_children[200] = { 300 }
assert_eq(lib_term.is_pi(7), true, 'pi below a wrapper process is detected')

-- deeper than PI_SEARCH_DEPTH: not detected
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'bash'
proc_names[300] = 'mise'
proc_names[400] = 'pi'
proc_children[100] = { 200 }
proc_children[200] = { 300 }
proc_children[300] = { 400 }
assert_eq(lib_term.is_pi(7), false, 'pi beyond the search depth is not detected')

-- a terminal running something else, and a non-terminal buffer
setup(true)
buf_types[7] = 'terminal'
buf_types[8] = ''
buf_pids[7] = 100
buf_pids[8] = 101
proc_names[100] = 'bash'
proc_names[101] = 'pi'
proc_children[100] = { 201 }
proc_names[201] = 'rg'
assert_eq(lib_term.is_pi(7), false, 'shell terminal without pi is not pi')
assert_eq(lib_term.is_pi(8), false, 'non-terminal buffer is never pi')

-- dead process / closed channel: no error, just false
setup(true)
buf_types[7] = 'terminal'
assert_eq(lib_term.is_pi(7), false, 'terminal with no live channel is not pi')
buf_pids[7] = 100
assert_eq(lib_term.is_pi(7), false, 'job pid that no longer exists is not pi')

-- result is cached per buffer, and the cache expires
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(lib_term.is_pi(7), true, 'pi detected before it exits')
proc_names[100] = nil
assert_eq(lib_term.is_pi(7), true, 'cached within the TTL even though pi exited')
clock = clock + 500
assert_eq(lib_term.is_pi(7), false, 'rescanned after the TTL: pi is gone')

-- ============================================================
describe('startinsert: skipped for pi terminals')

--- Run lib.term.startinsert against the mocked state, returning whether it
--- asked for insert mode.
---@param opts { insert: boolean, floating: boolean }
local function startinsert(opts)
  state.insert_when_entering_terminal = opts.insert
  vim_mock.api.nvim_get_current_win = function()
    return 1000
  end
  vim_mock.api.nvim_win_get_config = function()
    return { relative = opts.floating and 'editor' or '' }
  end
  cmds = {}
  lib_term.startinsert()
  return cmds[1] == 'startinsert'
end

-- a terminal running pi is left in normal mode: pi drives its own input box
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(startinsert({ insert = true, floating = false }), false, 'no startinsert in a pi terminal')

-- ...including a pi that has not exec'd yet (the TermOpen instant)
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:pi'
buf_pids[7] = 100
proc_names[100] = 'bash'
assert_eq(startinsert({ insert = true, floating = false }), false, 'no startinsert in a starting pi terminal')

-- any other terminal still gets insert mode
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:/usr/bin/bash'
buf_pids[7] = 100
proc_names[100] = 'bash'
assert_eq(startinsert({ insert = true, floating = false }), true, 'startinsert in a shell terminal')
assert_eq(startinsert({ insert = false, floating = false }), false, 'opt-out respected')
assert_eq(startinsert({ insert = true, floating = true }), false, 'floating terminal windows opt out')

io.write(string.format('\n\n%d/%d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
