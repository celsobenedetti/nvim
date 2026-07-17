--- Tests for statusline _build_section
--- Run with: luajit tests/statusline/test_build_section.lua

local function hl(group, text)
  return '%#' .. group .. '#' .. text .. '%*'
end

-- Mock the separators (simulating the real ones from the module)
local LEFT_SEPARATOR = hl('TextSecondary', '  ')
local RIGHT_SEPARATOR = hl('TextSecondary', '  ')

-- Replica of the (fixed) _build_section function
local function _build_section(segments, direction)
  local separator = direction == 'left' and LEFT_SEPARATOR or RIGHT_SEPARATOR
  local section = ''
  local has_content = false
  for _, segment in ipairs(segments) do
    local include = #segment > 0 and segment ~= ' '

    if include then
      if has_content then
        section = section .. separator
      end
      section = section .. segment
      has_content = true
    end
  end
  return section
end

-- {{{ Test utilities
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

local function assert_empty(got, msg)
  assert_eq(got, '', msg)
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end
-- }}}

-- ============================================================
describe('_build_section: empty and edge cases')

assert_empty(_build_section({}, 'left'), 'empty segments list')

assert_empty(
  _build_section({ '', '', '' }, 'left'),
  'all empty strings'
)

assert_empty(
  _build_section({ ' ', ' ', ' ' }, 'left'),
  'all space-only strings'
)

assert_empty(
  _build_section({ ' ' }, 'left'),
  'single space-only segment'
)

-- ============================================================
describe('_build_section: single non-empty segment')

assert_eq(
  _build_section({ 'hello' }, 'left'),
  'hello',
  'single segment, direction left'
)

assert_eq(
  _build_section({ 'world' }, 'right'),
  'world',
  'single segment, direction right'
)

assert_eq(
  _build_section({ '  has spaces  ' }, 'left'),
  '  has spaces  ',
  'single segment with leading/trailing spaces preserved'
)

-- ============================================================
describe('_build_section: first segment empty — no prefix separator')

-- This is THE bug: earlier code would emit a separator before the first
-- visible segment when index > 1 but earlier segments were empty.
local SEG_FILE = 'file.lua'
local SEG_BRANCH = '  main'

-- Left section: first segment (branch) empty, second (file) non-empty
local result = _build_section({ '', SEG_FILE }, 'left')
assert_eq(
  result,
  SEG_FILE,
  'first empty, second non-empty (left): no prefix separator'
)

-- Right section: first segment (macro) empty, second (formatters) non-empty
local result2 = _build_section({ '', '  stylua' }, 'right')
assert_eq(
  result2,
  '  stylua',
  'first empty, second non-empty (right): no prefix separator'
)

-- Multiple leading empties before first visible
local result3 = _build_section({ '', '', '', SEG_FILE }, 'left')
assert_eq(
  result3,
  SEG_FILE,
  'three empties then content: no prefix separator'
)

-- ============================================================
describe('_build_section: separators between visible segments')

-- Two non-empty segments
local result4 = _build_section({ SEG_BRANCH, SEG_FILE }, 'left')
assert_eq(
  result4,
  SEG_BRANCH .. LEFT_SEPARATOR .. SEG_FILE,
  'two non-empty segments separated by LEFT_SEPARATOR'
)

-- Three non-empty segments (right)
local SEG_A = 'A'
local SEG_B = 'B'
local SEG_C = 'C'
local result5 = _build_section({ SEG_A, SEG_B, SEG_C }, 'right')
assert_eq(
  result5,
  SEG_A .. RIGHT_SEPARATOR .. SEG_B .. RIGHT_SEPARATOR .. SEG_C,
  'three non-empty segments separated by RIGHT_SEPARATOR'
)

-- ============================================================
describe('_build_section: mixed empty and non-empty')

-- Non-empty, empty, non-empty
local result6 = _build_section({ SEG_A, '', SEG_C }, 'left')
assert_eq(
  result6,
  SEG_A .. LEFT_SEPARATOR .. SEG_C,
  'non-empty / empty / non-empty: separator between 1st and 3rd only'
)

-- Empty, non-empty, empty, non-empty
local result7 = _build_section({ '', SEG_B, '', SEG_A }, 'left')
assert_eq(
  result7,
  SEG_B .. LEFT_SEPARATOR .. SEG_A,
  'empty / non-empty / empty / non-empty: no prefix, one separator'
)

-- Non-empty, space-only, non-empty
local result8 = _build_section({ SEG_A, ' ', SEG_C }, 'left')
assert_eq(
  result8,
  SEG_A .. LEFT_SEPARATOR .. SEG_C,
  'non-empty / space / non-empty: separator between, space skipped'
)

-- ============================================================
describe('_build_section: direction determines separator')

-- Left direction uses LEFT_SEPARATOR
assert_eq(
  _build_section({ 'X', 'Y' }, 'left'),
  'X' .. LEFT_SEPARATOR .. 'Y',
  'left direction uses LEFT_SEPARATOR'
)

-- Right direction uses RIGHT_SEPARATOR
assert_eq(
  _build_section({ 'X', 'Y' }, 'right'),
  'X' .. RIGHT_SEPARATOR .. 'Y',
  'right direction uses RIGHT_SEPARATOR'
)

-- ============================================================
describe('_build_section: segment ~= " " check')

-- Segment with only whitespace chars but not exactly " "
-- These are NOT filtered out (intentional — only exactly " " is skipped)
local result9 = _build_section({ '', '  ', 'content' }, 'left')
assert_eq(
  result9,
  '  ' .. LEFT_SEPARATOR .. 'content',
  'segment with multiple spaces is treated as content, not skipped'
)

-- ============================================================
-- Summary
io.write(string.format(
  '\n\n%d / %d tests passed\n',
  tests_passed,
  tests_run
))

if tests_passed ~= tests_run then
  os.exit(1)
end
