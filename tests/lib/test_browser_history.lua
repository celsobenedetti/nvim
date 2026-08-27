--- Tests for lib.browser_history (MRU back/forward buffer navigation).
--- Run with: luajit tests/lib/test_browser_history.lua

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

local buf_state = {}

local vim_mock = {
  api = {
    nvim_buf_is_valid = function(id)
      return buf_state[id] and buf_state[id].valid or false
    end,
    nvim_buf_is_loaded = function(id)
      return buf_state[id] and buf_state[id].loaded or false
    end,
  },
}

mock.setup({ vim = vim_mock })

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

local function add_buf(id, overrides)
  buf_state[id] = { valid = true, loaded = true }
  for k, v in pairs(overrides or {}) do
    buf_state[id][k] = v
  end
end

local bh = require('lib.browser_history')

local function reset()
  buf_state = {}
  bh.reset()
end

-- ============================================================
describe('lib.browser_history.record: tracks most-recently-used order')

-- first recorded buffer seeds current
reset()
add_buf(1)
add_buf(2)
bh.record(1)
assert_eq(bh.prev(), nil, 'no older buffer after first record')
bh.record(2)
assert_eq(bh.prev(), 1, 'prev goes to the previously accessed buffer')
assert_eq(bh.next(), 2, 'next returns to the most recent buffer')
assert_eq(bh.next(), nil, 'no further buffer forward')

-- ============================================================
describe('lib.browser_history: the 3 -> 2 example from the plan')

reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
bh.record(3)
bh.record(2) -- user on 3 jumps to 2; 2 is now most recent
assert_eq(bh.prev(), 3, 'Bprev jumps to 3 (most recently left)')
assert_eq(bh.next(), 2, 'Bnext returns to 2')
assert_eq(bh.next(), nil, 'forward stack exhausted')
assert_eq(bh.prev(), 3, 'Bprev again goes back to 3')

-- ============================================================
describe('lib.browser_history: forward stack clears on fresh navigation')

reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
assert_eq(bh.prev(), 1, 'prev back to 1')
assert_eq(bh.prev(), nil, 'back stack empty')
assert_eq(bh.next(), 2, 'next forward to 2')
-- a fresh navigation clears the forward history
bh.record(3)
assert_eq(bh.next(), nil, 'forward cleared after navigating to a new buffer')
assert_eq(bh.prev(), 2, 'prev goes to 2')

-- ============================================================
describe('lib.browser_history.record: revisiting the current buffer is a no-op')

reset()
add_buf(1)
add_buf(2)
bh.record(1)
bh.record(2)
bh.record(2) -- BufEnter for the same buffer
assert_eq(bh.prev(), 1, 'no duplicate entry for same-buffer revisit')
assert_eq(bh.next(), 2, 'still one step forward')

-- ============================================================
describe('lib.browser_history: deep back/forward chains')

reset()
add_buf(1)
add_buf(2)
add_buf(3)
add_buf(4)
bh.record(1)
bh.record(2)
bh.record(3)
bh.record(4)
assert_eq(bh.prev(), 3, 'prev 4 -> 3')
assert_eq(bh.prev(), 2, 'prev 3 -> 2')
assert_eq(bh.next(), 3, 'next 2 -> 3')
assert_eq(bh.next(), 4, 'next 3 -> 4')
assert_eq(bh.next(), nil, 'no forward beyond 4')
assert_eq(bh.prev(), 3, 'prev 4 -> 3')

-- ============================================================
describe('lib.browser_history: prunes deleted buffers on access')

-- middle buffer deleted: prev skips over it
reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
bh.record(3)
buf_state[2].valid = false -- buffer 2 deleted
assert_eq(bh.prev(), 1, 'skips deleted buffer 2, lands on 1')
assert_eq(bh.next(), 3, 'next returns to 3')

-- deleted buffer at the head of the back stack is pruned and skipped
reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
bh.record(3)
bh.record(2)
buf_state[1].valid = false
assert_eq(bh.prev(), 3, 'skips deleted buffer 1, lands on 3')

-- unloaded buffers are also pruned
reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
bh.record(3)
buf_state[2].loaded = false
assert_eq(bh.prev(), 1, 'skips unloaded buffer 2')

-- ============================================================
describe('lib.browser_history: next prunes deleted buffers in forward stack')

reset()
add_buf(1)
add_buf(2)
add_buf(3)
bh.record(1)
bh.record(2)
bh.record(3)
bh.record(2)
assert_eq(bh.prev(), 3, 'prev 2 -> 3')
buf_state[2].valid = false -- the forward target is deleted
assert_eq(bh.next(), nil, 'prunes deleted forward buffer, nothing to return to')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
