local function colorize(s, color)
  return s -- no-op, add colors if you want
end

local function run_tests(suite)
  local passed, failed = 0, 0
  for _, case in ipairs(suite.tests) do
    local ok, err = pcall(case.fn)
    if ok then
      -- print("✔  " .. case.title)
      passed = passed + 1
    else
      print('✖  ' .. case.title)
      print('    ' .. err)
      failed = failed + 1
    end
  end
  return passed, failed
end

local all_suites = {}

function describe(title, fn)
  local suite = { title = title, tests = {} }
  local prev_suite = _G.__current_suite
  _G.__current_suite = suite
  fn()
  table.insert(all_suites, suite)
  _G.__current_suite = prev_suite
end

function it(title, fn)
  local suite = _G.__current_suite
  table.insert(suite.tests, { title = title, fn = fn })
end

assert = {}

function assert.equals(a, b)
  if a ~= b then
    error(('Expected %s but got %s'):format(tostring(b), tostring(a)), 2)
  end
end

function assert.same(a, b)
  local function cmp(x, y)
    if type(x) ~= type(y) then
      return false
    end
    if type(x) ~= 'table' then
      return x == y
    end
    for k, v in pairs(x) do
      if not cmp(v, y[k]) then
        return false
      end
    end
    for k, v in pairs(y) do
      if not cmp(v, x[k]) then
        return false
      end
    end
    return true
  end
  if not cmp(a, b) then
    error('Tables not same', 2)
  end
end

function assert.is_nil(a)
  if a ~= nil then
    error(('Expected nil but got %s'):format(tostring(a)), 2)
  end
end

function assert.is_true(a)
  if a ~= true then
    error(('Expected true but got %s'):format(tostring(a)), 2)
  end
end

function assert.is_false(a)
  if a ~= false then
    error(('Expected false but got %s'):format(tostring(a)), 2)
  end
end

function run_all_tests()
  local total_passed, total_failed = 0, 0
  for _, suite in ipairs(all_suites) do
    print('Suite: ' .. suite.title)
    local passed, failed = run_tests(suite)
    total_passed = total_passed + passed
    total_failed = total_failed + failed
    print ''
  end
  print(('Summary: %d passed, %d failed'):format(total_passed, total_failed))
end

return {
  run_all_tests = run_all_tests,
}
