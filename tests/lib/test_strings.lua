--- Tests for lib.strings.split_args (Grep command arg tokenizer)
--- Run with: luajit tests/lib/test_strings.lua
---
--- Pure functions; the only vim dependency is a mocked nvim_set_hl.

package.path = './lua/?.lua;' .. package.path

-- Minimal vim mock for colored_text (registers hex highlight groups)
local set_hl_calls = {}
vim = { api = {
  nvim_set_hl = function(ns, name, val)
    set_hl_calls[#set_hl_calls + 1] = { ns, name, val }
  end,
} }

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
describe('colored')

local colored = strings.colored
set_hl_calls = {}
assert_eq(colored('hi', '#51AF54'), '%#Hex51AF54#hi%*', 'wraps text in derived group markup')
assert_eq(#set_hl_calls, 1, 'registers one highlight group')
assert_eq(set_hl_calls[1][1], 0, 'group registered in global namespace')
assert_eq(set_hl_calls[1][2], 'Hex51AF54', 'group name derived from hex')
assert_eq(tostring(set_hl_calls[1][3].fg), '#51AF54', 'fg set to the hex color')
assert_eq(colored('x', '#51AF54'), '%#Hex51AF54#x%*', 'same hex reuses same group name')
assert_eq(colored('no color'), 'no color', 'nil hex returns plain text')
assert_eq(#set_hl_calls, 2, 'nil hex registers nothing')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
