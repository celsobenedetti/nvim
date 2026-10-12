--- Tests for lib.org (<leader>n dispatch).
--- Run with: luajit tests/lib/test_org.lua

package.path = './lua/?.lua;' .. package.path

local calls = {}

rawset(_G, 'vim', {
  v = { hlsearch = 0 },
  cmd = function(c)
    calls[#calls + 1] = c
  end,
})

package.loaded['orgmode'] = {
  action = function(name)
    calls[#calls + 1] = name
  end,
}

local org = require('lib.org')

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

org.add_note_or_search_next()
assert_eq(calls[1], 'org_mappings.add_note', 'adds a note when nothing is highlighted')

calls = {}
vim.v.hlsearch = 1
org.add_note_or_search_next()
assert_eq(calls[1], 'normal! n', 'jumps to the next match while hlsearch is on')

io.write(string.format('\n%d/%d passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
