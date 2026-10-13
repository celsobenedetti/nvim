--- Tests for lib.obsidian (which vault backs a buffer).
--- Run with: luajit tests/lib/test_obsidian.lua

package.path = './lua/?.lua;' .. package.path

local current_file = ''

rawset(_G, 'vim', {
  fn = {
    expand = function()
      return current_file
    end,
  },
})

rawset(_G, 'config', {
  org = { work = '/notes/org/work.org' },
  dirs = { work_notes = '/notes/work', garden = '/notes/garden' },
})

local obsidian = require('lib.obsidian')

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

assert_eq(obsidian.vault('/notes/org/work.org'), '/notes/work', 'work.org uses the work vault')
assert_eq(obsidian.vault('/notes/org/work.org_archive'), '/notes/work', 'the work archive follows work.org')
assert_eq(obsidian.vault('/notes/org/inbox.org'), '/notes/garden', 'other org files use the garden')
assert_eq(obsidian.vault('/notes/work/notes/x.md'), '/notes/work', 'notes inside the work vault stay there')
assert_eq(obsidian.vault('/notes/work'), '/notes/work', 'the vault root itself counts as inside')
assert_eq(obsidian.vault('/notes/workshop/x.md'), '/notes/garden', 'a sibling dir is not the work vault')
assert_eq(obsidian.vault('/notes/garden/notes/x.md'), '/notes/garden', 'garden notes use the garden')

current_file = '/notes/org/work.org'
assert_eq(obsidian.vault(), '/notes/work', 'defaults to the current buffer')

-- The agenda buffer has no file of its own, so the vault comes from the org
-- file backing the headline under the cursor, not from the current buffer.
current_file = '/tmp/orgagenda'
assert_eq(obsidian.vault('/notes/org/work.org'), '/notes/work', 'a source path overrides the current buffer')
assert_eq(obsidian.vault('/notes/org/personal.org'), '/notes/garden', 'a non-work source path uses the garden')
assert_eq(obsidian.vault(), '/notes/garden', 'no source path falls back to the current buffer')

assert_eq(obsidian.note_path('some note', ''), nil, 'an unconfigured vault resolves nothing')

current_file = '/notes/org/work.org'
config.org.work = ''
assert_eq(obsidian.vault(), '/notes/garden', 'unset ORG_WORK falls back to the garden')

io.write(string.format('\n%d/%d passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
