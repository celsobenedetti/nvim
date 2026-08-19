--- Tests for lib.visual visual-selection helpers
--- Run with: luajit tests/lib/test_visual.lua
---
--- Mocks the neovim api the module depends on. `vim.region()` is deprecated;
--- the module now uses `vim.fn.getregionpos()`, and the mock verifies that
--- replacement is the one called.

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

local function assert_truthy(got, msg)
  tests_run = tests_run + 1
  if got then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  got:      %q\n', msg, tostring(got)))
  end
end

local function assert_falsy(got, msg)
  tests_run = tests_run + 1
  if not got then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  got:      %q\n', msg, tostring(got)))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

-- Mutable state the mock reads from.
local buffer_lines = {}
local current_mode = 'v'
local selection_opt = 'inclusive'
local getpos_v = { 0, 1, 1, 0 }
local getpos_dot = { 0, 1, 1, 0 }
local regionpos_segments = {}
local regionpos_type = nil
local getregionpos_errors = false
local written = {}
local used_getregionpos = false
local used_deprecated_region = false

local function set_lines(bufnr, start, finish, strict_indexing, new_lines)
  local n = #new_lines
  for i = 1, n do
    buffer_lines[start + i] = new_lines[i]
  end
  for i = n + 1, finish - start do
    buffer_lines[start + i] = nil
  end
  table.insert(written, { start = start, finish = finish, new_lines = new_lines })
end

local function get_lines(bufnr, start, finish, strict_indexing)
  local out = {}
  for i = start + 1, finish do
    out[#out + 1] = buffer_lines[i] or ''
  end
  return out
end

local function reset(buf)
  buffer_lines = {}
  for i, line in ipairs(buf) do
    buffer_lines[i] = line
  end
  written = {}
  used_getregionpos = false
  used_deprecated_region = false
  regionpos_type = nil
  getregionpos_errors = false
  selection_opt = 'inclusive'
end

-- Configure a visual selection from {lnum1, col1} to {lnum2, col2} (1-indexed)
-- plus the segments `getregionpos` is expected to return. getregionpos returns
-- exclusive end columns, so a segment spanning bytes [c1, c2) has end col c2+1.
local function select(lnum1, col1, lnum2, col2, mode, segs)
  current_mode = mode or 'v'
  getpos_v = { 0, lnum1, col1, 0 }
  getpos_dot = { 0, lnum2, col2, 0 }
  regionpos_segments = segs or {
    { { 0, lnum1, col1, 0 }, { 0, lnum2, col2, 0 } },
  }
end

local function setup_vim()
  mock.setup({
    vim = {
      api = {
        nvim_get_mode = function()
          return { mode = current_mode }
        end,
        nvim_buf_get_lines = get_lines,
        nvim_buf_set_lines = set_lines,
        nvim_input = function(keys)
          table.insert(written, { input = keys })
        end,
      },
      fn = {
        getpos = function(expr)
          return expr == 'v' and getpos_v or getpos_dot
        end,
        -- visualmode() returns the *last* used visual mode; it is "" on the
        -- first visual selection in a buffer. The module must not depend on it.
        visualmode = function()
          return ''
        end,
        getregionpos = function(pos1, pos2, opts)
          used_getregionpos = true
          regionpos_type = opts.type
          if getregionpos_errors then
            error('Vim:E475: Invalid value for argument type: ')
          end
          return regionpos_segments
        end,
        region = function()
          used_deprecated_region = true
          return {}
        end,
        strpart = function(s, start, len)
          return string.sub(s, start + 1, start + len)
        end,
      },
      o = {
        selection = selection_opt,
      },
      split = function(s, sep, opts)
        local plain = opts and opts.plain
        local out = {}
        local pattern = plain and sep or '%s*' .. sep .. '%s*'
        for part in string.gmatch(s, plain and '[^' .. sep .. ']+' or pattern) do
          out[#out + 1] = part
        end
        if #out == 0 and s == '' then
          return { '' }
        end
        return out
      end,
    },
  })
end

local function last_write()
  for i = #written, 1, -1 do
    if written[i].new_lines then
      return written[i]
    end
  end
end

local function load_visual()
  return require('lib.visual')
end

local function unload_visual()
  mock.teardown({ 'vim' })
  package.loaded['lib.visual'] = nil
end

-- ============================================================
describe('lib.visual: uses getregionpos, not the deprecated vim.region')

reset({ 'aaaa' })
select(1, 1, 1, 4, 'v')
setup_vim()
local visual = load_visual()
visual.get_region()
assert_truthy(used_getregionpos, 'getregionpos is called')
assert_falsy(used_deprecated_region, 'deprecated vim.region is not called')
unload_visual()

-- ============================================================
describe('lib.visual: get_region returns 1-indexed start/end lines')

reset({ 'aaaa', 'bbbb', 'cccc' })
-- charwise selection spanning lines 1-3
select(1, 1, 3, 5, 'v', {
  { { 0, 1, 1, 0 }, { 0, 1, 4, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 4, 0 } },
  { { 0, 3, 1, 0 }, { 0, 3, 5, 0 } },
})
setup_vim()
visual = load_visual()
local start, finish = visual.get_region()
assert_eq(start, 1, 'start line (1-indexed)')
assert_eq(finish, 3, 'end line (1-indexed)')
unload_visual()

-- ============================================================
describe('lib.visual: get_region normalizes a backward selection')

reset({ 'aaaa', 'bbbb', 'cccc' })
-- cursor before the 'v' mark: getpos returns reversed positions, but the real
-- getregionpos normalizes internally, so segments come back in ascending order.
select(3, 5, 1, 1, 'v', {
  { { 0, 1, 1, 0 }, { 0, 1, 4, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 4, 0 } },
  { { 0, 3, 1, 0 }, { 0, 3, 5, 0 } },
})
setup_vim()
visual = load_visual()
local bstart, bfinish = visual.get_region()
assert_eq(bstart, 1, 'start is the earlier line')
assert_eq(bfinish, 3, 'end is the later line')
unload_visual()

-- ============================================================
describe('lib.visual: get_region for a linewise (V) selection')

reset({ 'aaaa', 'bbbb', 'cccc' })
select(2, 1, 3, 1, 'V', {
  { { 0, 2, 1, 0 }, { 0, 2, 2147483647, 0 } },
  { { 0, 3, 1, 0 }, { 0, 3, 2147483647, 0 } },
})
setup_vim()
visual = load_visual()
local vstart, vfinish = visual.get_region()
assert_eq(vstart, 2, 'linewise start line')
assert_eq(vfinish, 3, 'linewise end line')
unload_visual()

-- ============================================================
describe('lib.visual: returns nil when not in visual mode')

reset({ 'aaaa' })
current_mode = 'n'
setup_vim()
visual = load_visual()
assert_falsy(visual.get_region(), 'nil outside visual mode')
assert_falsy(visual.get_selection(), 'nil outside visual mode')
unload_visual()

-- ============================================================
describe('lib.visual: get_selection extracts the selected text (single line)')

reset({ '0123456789' })
-- selects bytes 1..3 (0-indexed) => "123"
select(1, 2, 1, 5, 'v')
setup_vim()
visual = load_visual()
assert_eq(visual.get_selection(), '123', 'selected substring returned')
unload_visual()

-- ============================================================
describe('lib.visual: get_selection across multiple lines')

reset({ 'aaaa', 'bbbb', 'cccc' })
-- line1 bytes 1..2 ("aa"), line2 whole ("bbbb"), line3 bytes 0..1 ("cc")
select(1, 2, 3, 3, 'v', {
  { { 0, 1, 2, 0 }, { 0, 1, 4, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 5, 0 } },
  { { 0, 3, 1, 0 }, { 0, 3, 3, 0 } },
})
setup_vim()
visual = load_visual()
assert_eq(visual.get_selection(), 'aa\nbbbb\ncc', 'joins lines with newline')
unload_visual()

-- ============================================================
describe('lib.visual: get_selection on a linewise (V) selection')

reset({ 'aaaa', 'bbbb' })
select(1, 1, 2, 1, 'V', {
  { { 0, 1, 1, 0 }, { 0, 1, 2147483647, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 2147483647, 0 } },
})
setup_vim()
visual = load_visual()
assert_eq(visual.get_selection(), 'aaaa\nbbbb', 'whole lines selected')
unload_visual()

-- ============================================================
describe('lib.visual: replace swaps the selected text')

reset({ '0123456789' })
-- selects bytes 1..3 => "123", replaced with "X"
select(1, 2, 1, 5, 'v')
setup_vim()
visual = load_visual()
visual.replace('X')
assert_eq(last_write().new_lines[1], '0X456789', 'replaced in place')
unload_visual()

-- replace spanning multiple lines collapses the selection to the new text
reset({ 'aaaa', 'bbbb' })
select(1, 2, 2, 3, 'v', {
  { { 0, 1, 2, 0 }, { 0, 1, 4, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 3, 0 } },
})
setup_vim()
visual = load_visual()
visual.replace('XYZ')
assert_eq(last_write().new_lines[1], 'aXYZbb', 'multi-line replacement')
unload_visual()

-- ============================================================
describe('lib.visual: wrap surrounds the selection')

reset({ '0123456789' })
select(1, 2, 1, 5, 'v')
setup_vim()
visual = load_visual()
visual.wrap('(', ')')
assert_eq(last_write().new_lines[1], '0(123)456789', 'wrapped in place')
unload_visual()

-- ============================================================
describe('lib.visual: wrap on a linewise selection wraps each line')

reset({ 'aaaa', 'bbbb' })
select(1, 1, 2, 1, 'V', {
  { { 0, 1, 1, 0 }, { 0, 1, 2147483647, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 2147483647, 0 } },
})
setup_vim()
visual = load_visual()
visual.wrap('>', '<')
local wrapped = last_write()
assert_eq(wrapped.new_lines[1], '>aaaa', 'first line prefixed')
assert_eq(wrapped.new_lines[2], 'bbbb<', 'last line suffixed')
unload_visual()

-- ============================================================
describe('lib.visual: uses the current mode, not visualmode()')

-- visualmode() is "" on the first visual selection in a buffer and stale
-- otherwise; the region type must come from nvim_get_mode().
reset({ 'aaaa' })
select(1, 1, 1, 4, 'v')
setup_vim()
visual = load_visual()
visual.get_region()
assert_eq(regionpos_type, 'v', 'charwise type from current mode')
unload_visual()

reset({ 'aaaa', 'bbbb' })
select(1, 1, 2, 1, 'V', {
  { { 0, 1, 1, 0 }, { 0, 1, 2147483647, 0 } },
  { { 0, 2, 1, 0 }, { 0, 2, 2147483647, 0 } },
})
setup_vim()
visual = load_visual()
visual.get_region()
assert_eq(regionpos_type, 'V', 'linewise type from current mode')
unload_visual()

-- getregionpos errors must surface as nil, not as a hard error
reset({ 'aaaa' })
select(1, 1, 1, 4, 'v')
getregionpos_errors = true
setup_vim()
visual = load_visual()
local ok, err = pcall(visual.get_region)
assert_truthy(ok, 'get_region does not throw')
assert_falsy(err, 'get_region returns nil instead of raising')
unload_visual()

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
