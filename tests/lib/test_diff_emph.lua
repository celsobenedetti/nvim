--- Tests for lib.diff_emph intra-line emphasis planning
--- Run with: luajit tests/lib/test_diff_emph.lua
---
--- Mocks the vim bits the lib touches; injects a naive LCS word-diff as
--- reference implementation so the tests validate parsing/mapping, not xdiff.

package.path = './lua/?.lua;' .. package.path

local function list_extend(t, other)
  for _, v in ipairs(other) do
    t[#t + 1] = v
  end
  return t
end

_G.vim = {
  list_extend = list_extend,
}

-- Naive LCS diff over '\n'-joined strings returning {start_a, count_a,
-- start_b, count_b} hunks (1-based), same contract as vim.text.diff indices.
local function split_lines(s)
  s = s:gsub('\n$', '')
  local out, start = {}, 1
  while true do
    local nl = s:find('\n', start, true)
    if not nl then
      break
    end
    out[#out + 1] = s:sub(start, nl - 1)
    start = nl + 1
  end
  out[#out + 1] = s:sub(start)
  return out
end

local function naive_diff(a_text, b_text)
  local A, B = split_lines(a_text), split_lines(b_text)
  local m, n = #A, #B
  local dp = {}
  for i = 0, m do
    dp[i] = {}
    for j = 0, n do
      if i == 0 or j == 0 then
        dp[i][j] = 0
      elseif A[i] == B[j] then
        dp[i][j] = dp[i - 1][j - 1] + 1
      else
        dp[i][j] = math.max(dp[i - 1][j], dp[i][j - 1])
      end
    end
  end

  local ops = {} -- backtracked, reverse chronological
  local i, j = m, n
  while i > 0 and j > 0 do
    if A[i] == B[j] then
      ops[#ops + 1] = { '=', i }
      i, j = i - 1, j - 1
    elseif dp[i - 1][j] >= dp[i][j - 1] then
      ops[#ops + 1] = { '-', i }
      i = i - 1
    else
      ops[#ops + 1] = { '+', j }
      j = j - 1
    end
  end
  while i > 0 do
    ops[#ops + 1] = { '-', i }
    i = i - 1
  end
  while j > 0 do
    ops[#ops + 1] = { '+', j }
    j = j - 1
  end

  local fwd = {}
  for k = #ops, 1, -1 do
    fwd[#fwd + 1] = ops[k]
  end

  local hunks, a_used, b_used = {}, 0, 0
  local k = 1
  while k <= #fwd do
    if fwd[k][1] == '=' then
      a_used, b_used = a_used + 1, b_used + 1
      k = k + 1
    else
      local dels, adds = {}, {}
      while k <= #fwd and fwd[k][1] ~= '=' do
        if fwd[k][1] == '-' then
          dels[#dels + 1] = fwd[k][2]
        else
          adds[#adds + 1] = fwd[k][2]
        end
        k = k + 1
      end
      hunks[#hunks + 1] = { dels[1] or a_used + 1, #dels, adds[1] or b_used + 1, #adds }
      a_used, b_used = a_used + #dels, b_used + #adds
    end
  end
  return hunks
end

local emph = require('lib.diff_emph')

local tests_run = 0
local tests_passed = 0

local function show(v)
  if type(v) ~= 'table' then
    return string.format('%q', tostring(v))
  end
  local parts = {}
  for k, val in pairs(v) do
    parts[#parts + 1] = tostring(k) .. '=' .. show(val)
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

local function equal(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= 'table' then
    return a == b
  end
  for k, v in pairs(a) do
    if not equal(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function assert_eq(got, expected, msg)
  tests_run = tests_run + 1
  if equal(got, expected) then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %s\n  got:      %s\n', msg, show(expected), show(got)))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

local function plan(lines)
  return emph.plan(lines, naive_diff)
end

local function region(row, col, end_, kind)
  return { row = row, col = col, end_ = end_, kind = kind }
end

-- ============================================================
describe('single modified line pair')

assert_eq(plan({ '@@ -1 +1 @@', '-foo bar baz', '+foo BAR baz' }), {
  region(1, 4, 7, 'del'),
  region(2, 4, 7, 'add'),
}, 'middle word emphasized on both sides')

-- ============================================================
describe('unpaired runs get nothing')

assert_eq(plan({ '+added line only' }), {}, 'pure insertion')
assert_eq(plan({ '-deleted line only' }), {}, 'pure deletion')
assert_eq(plan({ 'plain context' }), {}, 'no diff content')

-- ============================================================
describe('file headers are not content')

assert_eq(
  plan({
    'commit abc',
    'diff --git a/f b/f',
    '--- a/f',
    '+++ b/f',
    '@@ -1 +1 @@',
    '-x',
    '+yy',
  }),
  {
    region(5, 0, 1, 'del'),
    region(6, 0, 2, 'add'),
  },
  'headers skipped, body paired'
)

-- ============================================================
describe('total rewrite')

assert_eq(plan({ '-aaa', '+bbb' }), {
  region(0, 0, 3, 'del'),
  region(1, 0, 3, 'add'),
}, 'whole lines emphasized')

-- ============================================================
describe('multi-line block pairing')

assert_eq(
  plan({
    '-old alpha',
    '-old beta',
    '+fresh alpha',
    '+fresh beta',
  }),
  {
    region(0, 0, 3, 'del'),
    region(2, 0, 5, 'add'),
    region(1, 0, 3, 'del'),
    region(3, 0, 5, 'add'),
  },
  'unique shared words anchor alignment, per-hunk emission order'
)

-- ============================================================
describe('adjacent changed tokens merge across one space')

assert_eq(plan({ '-aa bb', '+AA BB' }), {
  region(0, 0, 5, 'del'),
  region(1, 0, 5, 'add'),
}, 'one span per line, not per word')

-- ============================================================
describe('unequal run sizes')

assert_eq(
  plan({
    '-keep this line',
    '-drop entirely',
    '+keep this line',
  }),
  {
    region(1, 0, 13, 'del'),
  },
  'extra deleted line fully emphasized'
)

-- ============================================================
describe('context separates change segments')

assert_eq(
  plan({
    '-a xx',
    '+a yy',
    ' ctx',
    '-b zz',
    '+b ww',
  }),
  {
    region(0, 2, 4, 'del'),
    region(1, 2, 4, 'add'),
    region(3, 2, 4, 'del'),
    region(4, 2, 4, 'add'),
  },
  'segments never cross context lines'
)

-- ============================================================
describe('deleted markdown hr misread guard')

-- `-` line whose content starts with `-- ` reads as `--- ` file header;
-- accepted tradeoff (same as diff-colors.lua classify()).
assert_eq(plan({ '--- looks like header', '+++ also header' }), {}, 'header prefixes skipped')

-- ============================================================
describe('blank lines inside a paired block')

-- Regression: blank +/- lines contribute no tokens; hunk indices must not
-- shift or point at nonexistent entries.
assert_eq(
  plan({
    '-keep',
    '-',
    '-tail gone',
    '+keep',
    '+',
    '+new tail',
  }),
  {
    region(5, 0, 3, 'add'),
    region(2, 5, 9, 'del'),
  },
  'only real changed words emphasized, no crash on empty content'
)

assert_eq(plan({ '-a', '-', '+a', '+' }), {}, 'matching blanks anchor nothing visible')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
