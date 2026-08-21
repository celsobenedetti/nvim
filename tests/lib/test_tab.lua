--- Tests for lib.tab tab helpers
--- Run with: luajit tests/lib/test_tab.lua
---
--- Mocks the neovim globals the module depends on (no tabby.nvim).

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

-- Mutable nvim state the mock reads from.
local tabpages = { ids = {}, current = nil }
local buf_names = {}
local input_callback = nil
local vim_g = {}
local buf_ft = {}
-- windows shown per tabpage id; defaults to { id } (one window per tab)
local tab_wins = {}
local vim_config = {
  icons = {
    term = '<term>',
    agent = '<agent>',
    git = { git = '', diff = '' },
    separator = { right = '|' },
  },
}

-- stub lib.term for the terminal special filetype label
local term_mock = {
  is_toggle_term = function()
    return false
  end,
  is_claude = function()
    return false
  end,
  is_opencode = function()
    return false
  end,
  is_pi = function()
    return false
  end,
}

local vim_mock = {
  api = {
    nvim_list_tabpages = function()
      return tabpages.ids
    end,
    nvim_get_current_tabpage = function()
      return tabpages.current
    end,
    nvim_tabpage_get_number = function(id)
      for i, t in ipairs(tabpages.ids) do
        if t == id then
          return i
        end
      end
      return 0
    end,
    nvim_tabpage_is_valid = function()
      return true
    end,
    nvim_tabpage_list_wins = function(id)
      return tab_wins[id] or { id }
    end,
    nvim_tabpage_get_win = function(id)
      return id
    end,
    nvim_win_get_buf = function(win)
      return win
    end,
    nvim_buf_get_name = function(buf)
      return buf_names[buf] or ''
    end,
    nvim_create_autocmd = function() end,
  },
  fn = {
    fnamemodify = function(name, mod)
      if mod ~= ':t' then
        return name
      end
      return name:match('[^/]+$') or name
    end,
  },
  ui = {
    input = function(_, cb)
      input_callback = cb
    end,
  },
  bo = setmetatable({}, {
    __index = function(_, buf)
      return {
        filetype = buf_ft[buf] or '',
      }
    end,
  }),
  tbl_keys = function(t)
    local keys = {}
    for k in pairs(t) do
      keys[#keys + 1] = k
    end
    return keys
  end,
  cmd = function() end,
  trim = function(s)
    return s:gsub('^%s+', ''):gsub('%s+$', '')
  end,
  g = vim_g,
  json = {
    encode = function(t)
      local parts = {}
      for k, v in pairs(t) do
        parts[#parts + 1] = k .. '|' .. v:gsub('|', '%%')
      end
      table.sort(parts)
      return table.concat(parts, '\n')
    end,
    decode = function(s)
      local t = {}
      for line in (s or ''):gmatch('[^\n]+') do
        local k, v = line:match('^([^|]+)|(.*)$')
        if k then
          t[k] = v
        end
      end
      return t
    end,
  },
}

mock.setup({ vim = vim_mock, state = vim_g, config = vim_config, lib = { term = term_mock } })

---Point the mock at a fresh set of tabpages (ids are arbitrary numbers; the
---tab *number* is their 1-based position). Optionally pre-seed saved names
---as the JSON string stored in vim.g.
local function reset(tabs, names_json)
  tabpages.ids = tabs or {}
  tabpages.current = (tabs and tabs[1]) or nil
  buf_names = {}
  buf_ft = {}
  tab_wins = {}
  vim_g.NamedTabs = names_json
  input_callback = nil
end

local function reload_tab()
  package.loaded['lib.tab'] = nil
  return require('lib.tab')
end

-- ============================================================
describe('lib.tab: available')

reset({ 0, 3, 5 })
local tab = reload_tab()
assert_eq(tab.available(), true, 'always available (home-grown)')

-- ============================================================
describe('lib.tab: rename')

reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('my tab')
assert_eq(tab.get_name(0), 'my tab', 'renames current tab')

-- specific tabid
reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('foo')
tab.rename('my tab', 5)
assert_eq(tab.get_name(5), 'my tab', 'renames given tab')
assert_eq(tab.get_name(0), 'foo', 'current tab untouched')

-- empty name prompts via vim.ui.input
reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('')
assert_eq(type(input_callback), 'function', 'prompts when name empty')
input_callback('prompted name')
assert_eq(tab.get_name(0), 'prompted name', 'prompt result renames tab')

-- prompt cancelled (nil) does not rename
reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('')
input_callback(nil)
assert_eq(vim_g.NamedTabs, nil, 'cancelled prompt does not rename')

-- ============================================================
describe('lib.tab: get_name')

reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('foo')
tab.rename('bar', 3)
assert_eq(tab.get_name(3), 'bar', 'named tab')
assert_eq(tab.get_name(), 'foo', 'defaults to current tab')

-- unnamed tab falls back to the current buffer name
reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('foo')
buf_names[5] = '/work/project/main.lua'
assert_eq(tab.get_name(5), 'main.lua', 'fallback to buffer basename')
assert_eq(tab.get_name(3), '[No Name]', 'fallback for unnamed buffer')

-- ============================================================
describe('lib.tab: special filetypes (single-buffer tabs)')

-- single-buffer tab with a special filetype gets the special label
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[5] = 'git'
assert_eq(tab.get_name(5), 'git', 'special label for ft=git')

-- fugitive
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[5] = 'fugitive'
assert_eq(tab.get_name(5), 'git|fugitive', 'special label for ft=fugitive')

-- picker buffer -> empty label
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[5] = 'snacks_picker_input'
assert_eq(tab.get_name(5), '', 'empty label for picker')

-- terminal defaults to the term icon + terminal
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[5] = 'terminal'
assert_eq(tab.get_name(5), '<term>terminal', 'special label for plain terminal')

-- special label beats explicit name only for unnamed tabs? explicit wins
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[5] = 'terminal'
tab.rename('my term', 5)
assert_eq(tab.get_name(5), 'my term', 'explicit name beats special label')

-- multi-buffer tab (two windows, different buffers) -> normal fallback
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[3] = 'git'
buf_names[3] = '/work/foo.lua' -- current window buffer (tab get_win returns id)
tab_wins[3] = { 3, 4 } -- two windows: buffer 3 (git) and buffer 4 (lua)
assert_eq(tab.get_name(3), 'foo.lua', 'multi-buffer tab ignores special handling')

-- two windows sharing one buffer (git) -> still special
reset({ 0, 3, 5 })
tab = reload_tab()
buf_ft[3] = 'git'
tab_wins[3] = { 3, 3 } -- both windows show buffer 3
assert_eq(tab.get_name(3), 'git', 'two windows on the same buffer keep special label')

-- ============================================================
describe('lib.tab: find')

-- tab numbers: id 0 -> tab 1, id 3 -> tab 2, id 5 -> tab 3
reset({ 0, 3, 5 }, vim_mock.json.encode({ ['1'] = 'git status', ['2'] = 'notes', ['3'] = 'git log' }))
tab = reload_tab()
assert_eq(tab.find('notes'), 3, 'finds tab by plain substring')
assert_eq(tab.find('git status'), 0, 'returns first matching tab')
assert_eq(tab.find('nothing'), nil, 'nil when no match')

-- ============================================================
describe('lib.tab: set_next_name / consume_next_name')

reset({ 0 })
tab = reload_tab()
assert_eq(tab.consume_next_name(), nil, 'empty before set')
tab.set_next_name('git diff main HEAD')
assert_eq(tab.consume_next_name(), 'git diff main HEAD', 'roundtrip')
assert_eq(tab.consume_next_name(), nil, 'cleared after consume')

-- ============================================================
describe('lib.tab: name_from_command')

reset({ 0 })
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

-- ============================================================
describe('lib.tab: persistence')

reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('hello')
assert_eq(type(vim_g.NamedTabs), 'string', 'saves to state.NamedTabs')
assert_eq(vim_g.NamedTabs, '1|hello', 'keyed by tab number')
tab = reload_tab()
assert_eq(tab.get_name(0), 'hello', 'name survives module reload')

-- ============================================================
describe('lib.tab: render')

reset({ 0, 3, 5 })
tab = reload_tab()
tab.rename('alpha')
local line = tab.render()
assert_eq(type(line), 'string', 'render returns a string')
assert_eq(line:find('alpha', 1, true) ~= nil, true, 'render includes tab name')
assert_eq(line:find('%1T', 1, true) ~= nil, true, 'render emits native tabpage labels')
assert_eq(line:find('%#Normal# ', 1, true) ~= nil, true, 'render spaces tabs apart with Normal hl')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
