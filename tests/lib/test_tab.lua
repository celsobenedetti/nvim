--- Tests for lib.tab tab helpers
--- Run with: luajit tests/lib/test_tab.lua
---
--- Mocks tabby.nvim and the neovim globals the module depends on.

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

-- In-memory tabby: name registry keyed by tabid.
local tabby_names = {}
local tabby_installed = true
local last_renamed = nil
local warn_called = nil
local input_callback = nil

local function setup_tabby(tabs)
  tabby_names = tabs or {}
  last_renamed = nil
  warn_called = nil
  input_callback = nil

  package.loaded['tabby'] = nil
  package.preload['tabby'] = function()
    return {
      tab_rename = function(name)
        last_renamed = name
        tabby_names[0] = name
      end,
    }
  end

  package.loaded['tabby.feature.tab_name'] = nil
  package.preload['tabby.feature.tab_name'] = function()
    return {
      get = function(tabid)
        return tabby_names[tabid] or ''
      end,
      set = function(tabid, name)
        last_renamed = name
        tabby_names[tabid] = name
      end,
    }
  end

  mock.setup({
    vim = {
      api = {
        nvim_list_tabpages = function()
          local ids = {}
          for k in pairs(tabby_names) do
            ids[#ids + 1] = k
          end
          table.sort(ids)
          return ids
        end,
      },
      ui = {
        input = function(_, cb)
          input_callback = cb
        end,
      },
      g = {
        icons = {
          git = {
            git = '',
            diff = '',
          },
        },
      },
      trim = function(s)
        return s:gsub('^%s+', ''):gsub('%s+$', '')
      end,
    },
    Snacks = {
      notify = {
        warn = function()
          warn_called = true
        end,
      },
    },
  })
end

local function teardown_tabby()
  package.loaded['tabby'] = nil
  package.preload['tabby'] = nil
  package.loaded['tabby.feature.tab_name'] = nil
  package.preload['tabby.feature.tab_name'] = nil
  mock.teardown({ 'vim', 'Snacks' })
end

local function reload_tab()
  package.loaded['lib.tab'] = nil
  return require('lib.tab')
end

-- ============================================================
describe('lib.tab: available')

setup_tabby({ [0] = 'foo' })
local tab = reload_tab()
assert_eq(tab.available(), true, 'true when tabby installed')
teardown_tabby()

tabby_installed = false
package.loaded['tabby'] = nil
package.preload['tabby'] = nil
mock.setup({ vim = { api = {}, ui = {} }, Snacks = { notify = { warn = function() end } } })
tab = reload_tab()
assert_eq(tab.available(), false, 'false when tabby missing')
teardown_tabby()
tabby_installed = true

-- ============================================================
describe('lib.tab: rename')

setup_tabby({ [0] = 'foo' })
tab = reload_tab()
tab.rename('my tab')
assert_eq(last_renamed, 'my tab', 'renames current tab')
teardown_tabby()

-- specific tabid
setup_tabby({ [0] = 'foo', [5] = 'bar' })
tab = reload_tab()
tab.rename('my tab', 5)
assert_eq(last_renamed, 'my tab', 'renames given tab')
assert_eq(tab.get_name(5), 'my tab', 'tab 5 renamed')
assert_eq(tab.get_name(0), 'foo', 'current tab untouched')
teardown_tabby()

-- empty name prompts via vim.ui.input
setup_tabby({ [0] = 'foo' })
tab = reload_tab()
tab.rename('')
assert_eq(type(input_callback), 'function', 'prompts when name empty')
input_callback('prompted name')
assert_eq(last_renamed, 'prompted name', 'prompt result renames tab')
teardown_tabby()

-- prompt cancelled (nil) does not rename
setup_tabby({ [0] = 'foo' })
tab = reload_tab()
tab.rename('')
input_callback(nil)
assert_eq(last_renamed, nil, 'cancelled prompt does not rename')
teardown_tabby()

-- tabby missing warns instead of renaming
package.loaded['tabby'] = nil
package.preload['tabby'] = nil
mock.setup({ vim = { api = {}, ui = {} }, Snacks = { notify = {
  warn = function()
    warn_called = true
  end,
} } })
tab = reload_tab()
tab.rename('x')
assert_eq(warn_called, true, 'warns when tabby missing')
teardown_tabby()

-- ============================================================
describe('lib.tab: get_name')

setup_tabby({ [0] = 'foo', [3] = 'bar' })
tab = reload_tab()
assert_eq(tab.get_name(3), 'bar', 'named tab')
assert_eq(tab.get_name(), 'foo', 'defaults to current tab')
teardown_tabby()

-- tabby missing returns nil
package.loaded['tabby.feature.tab_name'] = nil
package.preload['tabby.feature.tab_name'] = nil
mock.setup({ vim = { api = {}, ui = {} }, Snacks = { notify = { warn = function() end } } })
tab = reload_tab()
assert_eq(tab.get_name(3), nil, 'nil when tabby missing')
teardown_tabby()

-- ============================================================
describe('lib.tab: find')

setup_tabby({ [1] = 'git status', [3] = 'notes', [5] = 'git log' })
tab = reload_tab()
assert_eq(tab.find('notes'), 3, 'finds tab by plain substring')
assert_eq(tab.find('git'), 1, 'returns first matching tab')
assert_eq(tab.find('nothing'), nil, 'nil when no match')
teardown_tabby()

-- tabby missing returns nil
package.loaded['tabby.feature.tab_name'] = nil
package.preload['tabby.feature.tab_name'] = nil
mock.setup({ vim = { api = {}, ui = {} }, Snacks = { notify = { warn = function() end } } })
tab = reload_tab()
assert_eq(tab.find('notes'), nil, 'nil when tabby missing')
teardown_tabby()

-- ============================================================
describe('lib.tab: set_next_name / consume_next_name')

setup_tabby({ [0] = 'foo' })
tab = reload_tab()
assert_eq(tab.consume_next_name(), nil, 'empty before set')
tab.set_next_name('git diff main HEAD')
assert_eq(tab.consume_next_name(), 'git diff main HEAD', 'roundtrip')
assert_eq(tab.consume_next_name(), nil, 'cleared after consume')
teardown_tabby()

-- ============================================================
describe('lib.tab: name_from_command')

setup_tabby({ [0] = 'foo' })
tab = reload_tab()

assert_eq(tab.name_from_command('Git show abc123'), 'git show abc123', 'Git with args')
assert_eq(tab.name_from_command('tab Git show abc123'), 'git show abc123', 'tab Git with args')
assert_eq(tab.name_from_command(':Git show abc123'), 'git show abc123', 'leading colon')
assert_eq(tab.name_from_command('tab Git diff abc123..def456'), 'git diff abc123..def456', 'hash range')
assert_eq(tab.name_from_command('CodeDiff main HEAD'), 'diff main HEAD', 'CodeDiff with args')
assert_eq(tab.name_from_command('CodeDiff history'), 'diff history', 'CodeDiff history')
assert_eq(tab.name_from_command('tab Git'), nil, 'bare Git -> nil (defaults)')
assert_eq(tab.name_from_command('Git'), nil, 'bare Git no space -> nil')
assert_eq(tab.name_from_command('CodeDiff'), nil, 'bare CodeDiff -> nil (defaults)')
assert_eq(tab.name_from_command('e foo.lua'), nil, 'unrelated command -> nil')
assert_eq(tab.name_from_command(''), nil, 'empty command -> nil')

teardown_tabby()

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
