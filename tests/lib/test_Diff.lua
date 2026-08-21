--- Tests for lib.Diff_diff.parse_items (DiffDiff quickfix builder)
--- Run with: luajit tests/lib/test_Diff_diff.lua
---
--- Pure functions; no vim dependency.

package.path = './lua/?.lua;' .. package.path

local libDiff = require('lib.Diff')

local tests_run = 0
local tests_passed = 0

local function fmt(v)
  if type(v) == 'table' then
    local parts = {}
    for i = 1, #v do
      parts[i] = fmt(v[i])
    end
    return '{' .. table.concat(parts, ', ') .. '}'
  end
  return string.format('%q', tostring(v))
end

local function assert_eq(got, expected, msg)
  tests_run = tests_run + 1
  local ok = type(got) == type(expected)
  if ok and type(got) == 'table' then
    ok = #got == #expected
    if ok then
      for i = 1, #got do
        for k, v in pairs(expected[i]) do
          if got[i][k] ~= v then
            ok = false
          end
        end
      end
    end
  else
    ok = got == expected
  end
  if ok then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected: %s\n  got:      %s\n', msg, fmt(expected), fmt(got)))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end

local function lines(s)
  local t = {}
  for l in (s .. '\n'):gmatch('(.-)\n') do
    t[#t + 1] = l
  end
  return t
end

describe('parse_items: one entry per file, lnum at first hunk')
local sample = lines([[
diff --git a/a.txt b/a.txt
index f0f2307..c1dddf2 100644
--- a/a.txt
+++ b/a.txt
@@ -1,3 +1,4 @@
 l1
-l2
+CHANGED
 l3
+l4
diff --git a/b.txt b/b.txt
index 587be6b..975fbec 100644
--- a/b.txt
+++ b/b.txt
@@ -1 +1 @@
-x
+y
diff --git a/c.txt b/c.txt
new file mode 100644
index 0000000..3e75765
--- /dev/null
+++ b/c.txt
@@ -0,0 +1 @@
+new
]])
assert_eq(libDiff.parse_items(sample, 42), {
  { bufnr = 42, lnum = 5, text = 'a.txt' },
  { bufnr = 42, lnum = 15, text = 'b.txt' },
  { bufnr = 42, lnum = 23, text = 'c.txt' },
}, 'three changed files')

describe('parse_items: binary file points at section header')
local binary = lines([[
diff --git a/logo.png b/logo.png
index 1234567..89abcde 100644
Binary files a/logo.png and b/logo.png differ
]])
assert_eq(libDiff.parse_items(binary, 7), { { bufnr = 7, lnum = 1, text = 'logo.png' } }, 'binary section')

describe('parse_items: pure rename (no hunks) uses new name at header')
local renamed = lines([[
diff --git a/old.txt b/new.txt
similarity index 100%
rename from old.txt
rename to new.txt
]])
assert_eq(libDiff.parse_items(renamed, 3), { { bufnr = 3, lnum = 1, text = 'new.txt' } }, 'pure rename')

describe('parse_items: trailing hunkless section flushed at EOF')
local trailing = lines([[
diff --git a/a.txt b/a.txt
index f0f2307..c1dddf2 100644
--- a/a.txt
+++ b/a.txt
@@ -1 +1 @@
-x
+y
diff --git a/data.bin b/data.bin
index 1111111..2222222 100644
Binary files a/data.bin and b/data.bin differ
]])
assert_eq(libDiff.parse_items(trailing, 9), {
  { bufnr = 9, lnum = 5, text = 'a.txt' },
  { bufnr = 9, lnum = 8, text = 'data.bin' },
}, 'text file then binary tail')

describe('parse_items: degenerate inputs')
assert_eq(libDiff.parse_items({}, 1), {}, 'empty diff buffer')
assert_eq(libDiff.parse_items({ 'not a diff' }, 1), {}, 'non-diff content')

io.write(string.format('\n%d/%d passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
