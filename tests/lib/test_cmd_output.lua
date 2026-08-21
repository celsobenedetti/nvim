--- Tests for lib.cmd_output command-output helpers
--- Run with: luajit tests/lib/test_cmd_output.lua

package.path = './lua/?.lua;' .. package.path

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

local function assert_deep_eq(got, expected, msg)
  local function join(t)
    local parts = {}
    for i, v in ipairs(t) do
      parts[i] = string.format('%q', v)
    end
    return '{' .. table.concat(parts, ', ') .. '}'
  end
  local got_str = join(got)
  local exp_str = join(expected)
  tests_run = tests_run + 1
  if got_str == exp_str then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %s\n  got:      %s\n', msg, exp_str, got_str))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

local cmd_output = require('lib.cmd_output')

describe('parse_command')
assert_eq(cmd_output.parse_command(':!man tmux\r\n'), 'man tmux', 'strips :! prefix and CRLF')
assert_eq(cmd_output.parse_command(':!ls -la\n'), 'ls -la', 'strips LF')
assert_eq(cmd_output.parse_command(':!echo hi'), 'echo hi', 'no trailing newline')
assert_eq(cmd_output.parse_command(':!'), '', 'bare bang')

describe('to_lines')
assert_deep_eq(cmd_output.to_lines(''), {}, 'empty input')
assert_deep_eq(cmd_output.to_lines('one\ntwo\n'), { 'one', 'two' }, 'LF terminated, no trailing empty')
assert_deep_eq(cmd_output.to_lines('one\r\ntwo\r\n'), { 'one', 'two' }, 'CRLF terminated')
assert_deep_eq(cmd_output.to_lines('one\rtwo'), { 'one', 'two' }, 'lone CR acts as newline')
assert_deep_eq(cmd_output.to_lines('one\ntwo'), { 'one', 'two' }, 'unterminated last line kept')
assert_deep_eq(cmd_output.to_lines('\n\n'), {}, 'only blank lines')
assert_deep_eq(cmd_output.to_lines('a\n\nb\n'), { 'a', '', 'b' }, 'interior blank line kept')

describe('filetype_for')
assert_eq(cmd_output.filetype_for('man tmux'), 'man', 'man page')
assert_eq(cmd_output.filetype_for('  man  bash'), 'man', 'leading whitespace and extra spaces')
assert_eq(cmd_output.filetype_for('man'), nil, 'bare man is not a page')
assert_eq(cmd_output.filetype_for('git status'), nil, 'non-man command')
assert_eq(cmd_output.filetype_for(''), nil, 'empty command')

io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))
if tests_passed ~= tests_run then
  os.exit(1)
end
