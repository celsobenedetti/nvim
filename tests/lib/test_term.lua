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

local vim_mock = {
  api = {
    nvim_get_current_buf = function()
      return current_buf
    end,
  },
  bo = setmetatable({}, {
    __index = function(_, buf)
      return { buftype = buf_types[buf] or '' }
    end,
  }),
}

---@param with_agents boolean whether state.agents is populated
local function setup(with_agents)
  current_buf = 1
  buf_types = {}
  agent_bufs = {}
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
assert_eq(lib_term.is_pi(42), false, 'no state.agents -> is_pi false')

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
assert_eq(lib_term.is_pi(42), false, 'claude buffer is not pi')
assert_eq(lib_term.is_agent(7), false, 'other terminal buffer not an agent')

-- pi terminal registered alongside claude
setup(true)
current_buf = 7
buf_types[7] = 'terminal'
buf_types[42] = 'terminal'
agent_bufs.claude = 42
agent_bufs.pi = 7
assert_eq(lib_term.is_pi(), true, 'is_pi() detects current buffer')
assert_eq(lib_term.is_pi(7), true, 'is_pi(bufnr) detects explicit buffer')
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

io.write(string.format('\n\n%d/%d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
