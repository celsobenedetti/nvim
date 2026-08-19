--- Tests for lib.strings.split_args (Grep command arg tokenizer)
--- Run with: luajit tests/lib/test_strings.lua
---
--- Pure function, no vim mock needed.

package.path = './lua/?.lua;' .. package.path

local strings = require('lib.strings')

local tests_run = 0
local tests_passed = 0

local function fmt(v)
  if type(v) == 'table' then
    local parts = {}
    for i, x in ipairs(v) do
      parts[i] = string.format('%q', x)
    end
    return '{' .. table.concat(parts, ', ') .. '}'
  end
  return string.format('%q', v)
end

local function same_list(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then
    return a == b
  end
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local function assert_eq(got, expected, msg)
  tests_run = tests_run + 1
  if same_list(got, expected) then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %s\n  got:      %s\n', msg, fmt(expected), fmt(got)))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

local split = strings.split_args

-- ============================================================
describe('whitespace splitting')

assert_eq(split(''), {}, 'empty string')
assert_eq(split('   '), {}, 'whitespace only')
assert_eq(split('one'), { 'one' }, 'single token')
assert_eq(split('foo bar baz'), { 'foo', 'bar', 'baz' }, 'plain split')
assert_eq(split('foo\tbar'), { 'foo', 'bar' }, 'tab is a separator')

-- ============================================================
describe('quoting')

assert_eq(split('"some query" file.txt'), { 'some query', 'file.txt' }, 'double-quoted token')
assert_eq(split("'some query' file.txt"), { 'some query', 'file.txt' }, 'single-quoted token')
assert_eq(split('a "b c" d'), { 'a', 'b c', 'd' }, 'quote mid-line')
assert_eq(split('"a \\"quoted\\" word" x'), { 'a "quoted" word', 'x' }, 'escaped quote inside quotes')

-- ============================================================
describe('backslash escapes (space, quote, backslash)')

assert_eq(split('foo\\ bar'), { 'foo bar' }, 'escaped space stays in one token')
assert_eq(split('a\\\\b'), { 'a\\b' }, 'escaped backslash')
assert_eq(split('foo\\'), { 'foo\\' }, 'trailing backslash kept verbatim')

-- ============================================================
describe('regex backslashes kept (the \bfoo\bbar regression)')

assert_eq(split('\\bfoo\\bbar file.txt'), { '\\bfoo\\bbar', 'file.txt' }, 'word-boundary pattern intact')
assert_eq(split('\\d+\\s+file'), { '\\d+\\s+file' }, 'digit/space classes intact')
assert_eq(split('a\\.b c'), { 'a\\.b', 'c' }, 'escaped dot intact')
assert_eq(split('"\\bquoted\\b" x'), { '\\bquoted\\b', 'x' }, 'backslashes survive inside quotes')
assert_eq(split('\\t'), { '\\t' }, 'backslash-t kept (rg tab escape, not a literal tab)')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
