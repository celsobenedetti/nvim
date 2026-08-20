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

io.write(string.format('\n\n%d/%d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
