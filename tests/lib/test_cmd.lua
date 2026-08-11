--- Tests for lib.cmd command-history helpers
--- Run with: luajit tests/lib/test_cmd.lua
---
--- Mocks the neovim vim.fn.hist* functions it depends on.

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

-- In-memory command history: hist[n] returns entry for index n, '' for gaps.
local history = { 'git status', 'CodeDiff main HEAD', 'git log --oneline' }

local function setup_hist(entries)
  history = entries
  mock.setup({
    vim = {
      fn = {
        histnr = function()
          return #history
        end,
        histget = function(_, idx)
          if idx == -1 then
            return history[#history] or ''
          end
          return history[idx] or ''
        end,
      },
    },
  })
end

local cmd

-- ============================================================
describe('lib.cmd: get_last_command')

setup_hist({ 'git status', 'CodeDiff main HEAD', 'git log --oneline' })
cmd = require('lib.cmd')
assert_eq(cmd.get_last_command(), 'git log --oneline', 'returns most recent command')
mock.teardown({ 'vim' })
package.loaded['lib.cmd'] = nil

setup_hist({})
cmd = require('lib.cmd')
assert_eq(cmd.get_last_command(), '', 'empty history returns empty string')
mock.teardown({ 'vim' })
package.loaded['lib.cmd'] = nil

-- ============================================================
describe('lib.cmd: get_command_history')

setup_hist({ 'git status', 'CodeDiff main HEAD', 'git log --oneline' })
cmd = require('lib.cmd')
local got = cmd.get_command_history()
assert_eq(got[1], 'git log --oneline', 'most recent first')
assert_eq(got[2], 'CodeDiff main HEAD', 'second entry')
assert_eq(got[3], 'git status', 'oldest last')
assert_eq(#got, 3, 'all entries returned')
mock.teardown({ 'vim' })
package.loaded['lib.cmd'] = nil

-- empty history
setup_hist({})
cmd = require('lib.cmd')
assert_eq(#cmd.get_command_history(), 0, 'empty history')
mock.teardown({ 'vim' })
package.loaded['lib.cmd'] = nil

-- ============================================================
describe('lib.cmd: get_command_history filters empty slots')

-- history with gaps (histget returns '' for non-contiguous indices)
mock.setup({
  vim = {
    fn = {
      histnr = function()
        return 5
      end,
      histget = function(_, idx)
        if idx == -1 then
          return 'last'
        end
        local map = { [5] = 'last', [3] = 'middle', [1] = 'first' }
        return map[idx] or ''
      end,
    },
  },
})
cmd = require('lib.cmd')
local got2 = cmd.get_command_history()
assert_eq(#got2, 3, 'empty slots dropped')
assert_eq(got2[1], 'last', 'most recent first')
assert_eq(got2[2], 'middle', 'second entry')
assert_eq(got2[3], 'first', 'oldest last')
mock.teardown({ 'vim' })
package.loaded['lib.cmd'] = nil

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
