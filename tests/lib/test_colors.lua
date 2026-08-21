--- Tests for lib.colors hex helpers
--- Run with: luajit tests/lib/test_colors.lua
---
--- Pure functions, no vim mock needed.

package.path = './lua/?.lua;' .. package.path

local colors = require('lib.colors')

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

-- ============================================================
describe('blend')

assert_eq(colors.blend('#000000', '#ffffff'), '#808080', 'black + white = mid gray')
assert_eq(colors.blend('#ffffff', '#000000'), '#808080', 'order independent')
assert_eq(colors.blend('#ff0000', '#00ff00'), '#808000', 'red + green')
assert_eq(colors.blend('#102030', '#102030'), '#102030', 'same color unchanged')
assert_eq(colors.blend('#010101', '#020202'), '#020202', '.5 sums round up')
assert_eq(colors.blend('#ff8000', '#000000'), '#804000', 'halves each channel')
assert_eq(colors.blend('#aabbcc', '#ddeeff'), '#c4d5e6', 'mixed channels')

assert_eq(colors.darken('#ffffff', 1), '#000000', 'darken to black')
assert_eq(colors.darken('#ffffff', 0), '#ffffff', 'darken by zero is no-op')
assert_eq(colors.lighten('#000000', 1), '#ffffff', 'lighten to white')
assert_eq(colors.lighten('#000000', 0), '#000000', 'lighten by zero is no-op')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
