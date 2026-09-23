--- Tests for the lib.term primitives: the tailing decision (was_following),
--- agent terminal identity, terminal job/process inspection, and the
--- startinsert-on-terminal-enter decision. pi's use of them is covered by
--- tests/plugin/test_pi.lua.
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
describe('terminal job primitives')

-- job_pid: from the buffer's channel, nil when there is no live channel
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
assert_eq(lib_term.job_pid(7), 100, 'job_pid returns the channel job pid')
buf_pids[7] = nil
assert_eq(lib_term.job_pid(7), nil, 'job_pid is nil without a live channel')

-- job_command: the command part of `term://{cwd}//{pid}:{cmd}`
setup(true)
buf_types[7] = 'terminal'
buf_names[7] = 'term://~/projects/nvim//100:pi --resume'
assert_eq(lib_term.job_command(7), 'pi --resume', 'job_command reads the command from the buffer name')
buf_names[7] = 'term://~/projects/nvim//100:/usr/bin/bash'
assert_eq(lib_term.job_command(7), '/usr/bin/bash', 'job_command keeps an absolute command path')
buf_names[8] = '/home/me/notes.md'
assert_eq(lib_term.job_command(8), nil, 'job_command is nil for a non-terminal buffer name')

-- job_runs_process: the job process itself
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'pi'
assert_eq(lib_term.job_runs_process(7, 'pi'), true, 'job process matched by name')
assert_eq(lib_term.job_runs_process(7, 'claude'), false, 'job process not matched by another name')

-- job_runs_process: descendants, within the requested depth
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'pi'
proc_children[100] = { 200 }
assert_eq(lib_term.job_runs_process(7, 'pi'), true, 'child of the job process matched at default depth')

setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100
proc_names[100] = 'bash'
proc_names[200] = 'mise'
proc_names[300] = 'pi'
proc_children[100] = { 200 }
proc_children[200] = { 300 }
assert_eq(lib_term.job_runs_process(7, 'pi'), false, 'grandchild is beyond the default depth')
assert_eq(lib_term.job_runs_process(7, 'pi', 2), true, 'grandchild matched at depth 2')
assert_eq(lib_term.job_runs_process(7, 'pi', 1), false, 'grandchild not matched at depth 1')

-- job_runs_process: nothing to inspect
setup(true)
buf_types[7] = 'terminal'
buf_types[8] = ''
buf_pids[8] = 101
proc_names[101] = 'pi'
assert_eq(lib_term.job_runs_process(7, 'pi'), false, 'terminal without a live channel runs nothing')
assert_eq(lib_term.job_runs_process(8, 'pi'), false, 'non-terminal buffer runs nothing')
setup(true)
buf_types[7] = 'terminal'
buf_pids[7] = 100 -- pid with no /proc entry: the process is already gone
assert_eq(lib_term.job_runs_process(7, 'pi'), false, 'job pid that no longer exists runs nothing')

-- ============================================================
describe('startinsert')

--- Run lib.term.startinsert against the mocked state, returning whether it
--- asked for insert mode.
---@param opts { insert: boolean, floating: boolean?, exempt: (fun(buffer: integer): boolean)? }
local function startinsert(opts)
  state.insert_when_entering_terminal = opts.insert
  vim_mock.api.nvim_get_current_win = function()
    return 1000
  end
  vim_mock.api.nvim_win_get_config = function()
    return { relative = opts.floating and 'editor' or '' }
  end
  local exemptions = lib_term.startinsert_exemptions
  for i = #exemptions, 1, -1 do
    exemptions[i] = nil
  end
  if opts.exempt then
    table.insert(exemptions, opts.exempt)
  end
  cmds = {}
  lib_term.startinsert()
  return cmds[1] == 'startinsert'
end

setup(true)
current_buf = 7
buf_types[7] = 'terminal'
assert_eq(startinsert({ insert = true }), true, 'startinsert on entering a terminal')
assert_eq(startinsert({ insert = false }), false, 'opt-out respected')
assert_eq(startinsert({ insert = true, floating = true }), false, 'floating terminal windows opt out')

-- exemptions registered by plugin files (after/plugin/pi.lua) win
assert_eq(
  startinsert({
    insert = true,
    exempt = function(buffer)
      return buffer == 7
    end,
  }),
  false,
  'an exemption matching the entered buffer suppresses insert mode'
)
assert_eq(
  startinsert({
    insert = true,
    exempt = function(buffer)
      return buffer == 42
    end,
  }),
  true,
  'an exemption for another buffer does not suppress insert mode'
)

io.write(string.format('\n\n%d/%d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
