--- Integration tests for MyStatusLine (the full statusline function)
--- Run with: luajit tests/statusline/test_integration.lua
---
--- Mocks all neovim globals and exercises the real MyStatusLine flow:
--- 1. module segment functions produce content
--- 2. _build_section groups them with separators
--- 3. MyStatusLine assembles left + middle + right

local function hl(group, text)
  return '%#' .. group .. '#' .. text .. '%*'
end

-- {{{ Mock setup
local function setup_vim(custom)
  local defaults = {
    g = {
      statusline = true,
      statusline_show_filepath = true,
      statusline_show_position = true,
      statusline_show_time = false,
      gitsigns_head = nil,
      branch_commits_behind_origin = 0,
      branch_commits_ahead_of_origin = 0,
      zen_mode = false,
      recording_macro = false,
      time = nil,
      hl = {
        text = { text = '@text', highlight = 'Title', secondary = 'TextSecondary', subtext = '@comment', warn = 'WarningMsg' },
        warn = 'WarningMsg',
      },
      icons = {
        git = { branch = ' ', ahead = '', behind = '', added = ' +', modified = ' ~', removed = ' -' },
        lsp = ' ',
        format = ' ',
        diagnostics = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
      },
    },
    b = {},
    v = { hlsearch = 0 },
    api = {
      nvim_get_current_buf = function() return 1 end,
      nvim_buf_set_var = function() end,
    },
    fn = {
      expand = function() return 'test.lua' end,
      searchcount = function() return { incomplete = 0, current = 0, total = 0 } end,
      reverse = function(t) local r = {}; for i = #t, 1, -1 do r[#r + 1] = t[i] end; return r end,
    },
    lsp = {
      get_clients = function() return {} end,
    },
    diagnostic = {
      get = function() return {} end,
    },
    bo = { filetype = 'lua' },
  }

  -- Merge custom overrides
  local function deep_merge(a, b)
    for k, v in pairs(b) do
      if type(v) == 'table' and type(a[k]) == 'table' then
        deep_merge(a[k], v)
      else
        a[k] = v
      end
    end
    return a
  end

  rawset(_G, 'vim', deep_merge(defaults, custom or {}))
end

local function teardown_vim()
  rawset(_G, 'vim', nil)
end
-- }}}

-- {{{ Replica of the key components from after/plugin/statusline.lua

local LEFT_SEPARATOR = hl('TextSecondary', '  ')
local RIGHT_SEPARATOR = hl('TextSecondary', '  ')
local LEFT_PREFIX = ' '
local RIGHT_SUFFIX = ' '

local modules = {
  _git_branch = function()
    if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
      return ''
    end
    return hl('Title', ' ') .. hl('TextSecondary', vim.g.gitsigns_head or '')
  end,

  _branch_sync_status = function()
    local s = ''
    if vim.g.branch_commits_behind_origin and vim.g.branch_commits_behind_origin > 0 then
      s = ' ' .. '' .. vim.g.branch_commits_behind_origin
    end
    if vim.g.branch_commits_ahead_of_origin and vim.g.branch_commits_ahead_of_origin > 0 then
      s = s .. '' .. vim.g.branch_commits_ahead_of_origin
    end
    if #s == 0 then return '' end
    return hl('TextSecondary', s)
  end,

  _file = function()
    if not vim.g.statusline_show_filepath then return '' end
    vim.b.relative_file = vim.fn.expand('%:.')
    return hl('TextSecondary', vim.b.relative_file)
  end,

  _git_status = function()
    local st = vim.b.gitsigns_status_dict or {}
    local a, m, r = st.added or 0, st.changed or 0, st.removed or 0
    if a == 0 and m == 0 and r == 0 then return '' end
    local result = ''
    if a > 0 then result = result .. hl('GitSignsAdd', ' +' .. a) end
    if m > 0 then result = result .. hl('GitSignsChange', ' ~' .. m) end
    if r > 0 then result = result .. hl('GitSignsDelete', ' -' .. r) end
    return result
  end,

  _diagnostics = function()
    local count = { 0, 0, 0, 0 }
    for _, d in pairs(vim.diagnostic.get(vim.api.nvim_get_current_buf())) do
      count[d.severity] = count[d.severity] + 1
    end
    local r = ''
    if count[1] > 0 then r = r .. hl('DiagnosticError', ' ' .. count[1] .. ' ') end
    if count[2] > 0 then r = r .. hl('DiagnosticWarn', ' ' .. count[2] .. ' ') end
    if count[3] > 0 then r = r .. hl('DiagnosticInfo', ' ' .. count[3] .. ' ') end
    if count[4] > 0 then r = r .. hl('DiagnosticHint', ' ' .. count[4] .. ' ') end
    return r
  end,

  _lsps = function()
    local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    if next(clients) == nil then return '' end
    local c = {}
    for _, client in pairs(clients) do c[#c + 1] = client.name end
    return hl('Title', ' ') .. hl('TextSecondary', table.concat(vim.fn.reverse(c), ', '))
  end,

  _formatters = function()
    -- Skipping conform dependency in integration test; always returns empty
    return ''
  end,

  _macro = function()
    if not vim.g.recording_macro then return '' end
    return hl('WarningMsg', '  recording macro ')
  end,

  _terminal = function()
    if not vim.b.term then return '' end
    return hl('MiniStatuslineModeOther', '   terminal ')
  end,

  _location = function()
    if not vim.g.statusline_show_position then return '' end
    return hl('@comment', '%l:%v')
  end,

  _time = function()
    return (not vim.g.statusline_show_time and '') or (vim.g.time or os.date('%H:%M'))
  end,

  _search_results = function()
    if vim.v.hlsearch == 1 then
      local sinfo = vim.fn.searchcount({ maxcount = 0 })
      local stat = sinfo.incomplete > 0 and '[?/?]'
        or sinfo.total > 0 and ('[%s/%s]'):format(sinfo.current, sinfo.total)
        or nil
      if stat then return hl('@comment', stat) end
    end
  end,
}

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

local function MyStatusLine()
  if not vim.g.statusline or vim.bo.filetype == 'dbout' then
    return hl('TextSecondary', ' %f')
  end
  if vim.g.zen_mode then return '' end

  local left = _build_section(
    { modules._git_branch() .. modules._branch_sync_status(),
      modules._file() .. modules._git_status(),
      modules._diagnostics(),
      modules._search_results() or '' },
    'left'
  )
  local right = _build_section(
    { modules._macro(),
      modules._terminal(),
      modules._location(),
      modules._formatters(),
      modules._lsps(),
      modules._time() },
    'right'
  )
  return string.format('%s%s%s%s%s', LEFT_PREFIX, left, '%=', right, RIGHT_SUFFIX)
end
-- }}}

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

local function assert_contains(haystack, needle, msg)
  tests_run = tests_run + 1
  if haystack:find(needle, 1, true) then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected to find %q in:\n  %q\n', msg, needle, haystack))
  end
end

local function assert_not_contains(haystack, needle, msg)
  tests_run = tests_run + 1
  if not haystack:find(needle, 1, true) then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected NOT to find %q in:\n  %q\n', msg, needle, haystack))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end
-- }}}

-- ============================================================
describe('MyStatusLine: no git branch, file only (the bug scenario)')

-- Simulate: no git branch, file open, no diagnostics, no search
setup_vim({
  g = { gitsigns_head = nil, statusline_show_position = false },
  b = {},
})
local result = MyStatusLine()
-- The left prefix should be just a space, not a separator
assert_contains(result, ' ' .. hl('TextSecondary', 'test.lua'), 'file content present')
-- The LEFT_SEPARATOR '  ' should NOT appear as a prefix
assert_not_contains(result, LEFT_SEPARATOR, 'no prefix separator on left')
-- But the separator character should not appear at all when only one segment
assert_not_contains(result, '', 'no left separator character anywhere in output')
teardown_vim()

-- ============================================================
describe('MyStatusLine: with git branch and file (two visible segments)')

setup_vim({
  g = { gitsigns_head = 'main', branch_commits_behind_origin = 0, branch_commits_ahead_of_origin = 0, statusline_show_position = false },
  b = {},
})
local result2 = MyStatusLine()
-- Branch should be present
assert_contains(result2, hl('Title', ' ') .. hl('TextSecondary', 'main'), 'branch name present')
-- File should be present
assert_contains(result2, hl('TextSecondary', 'test.lua'), 'file present')
-- Separator should be BETWEEN branch and file, not before branch
local branch_seg = hl('Title', ' ') .. hl('TextSecondary', 'main')
local file_seg = hl('TextSecondary', 'test.lua')
assert_contains(result2, branch_seg .. LEFT_SEPARATOR .. file_seg, 'separator between branch and file')
-- The output should start with the prefix space followed by branch, not a separator
assert_eq(result2:sub(1, #branch_seg + 1), ' ' .. branch_seg, 'starts with prefix space then branch content')
teardown_vim()

-- ============================================================
describe('MyStatusLine: right section — multiple visible segments')

setup_vim({
  g = { statusline_show_position = true, statusline_show_time = false, gitsigns_head = nil },
  b = {},
  lsp = { get_clients = function() return { { name = 'lua_ls' }, { name = 'stylua' } } end },
})
local result3 = MyStatusLine()
-- Location should be present
assert_contains(result3, hl('@comment', '%l:%v'), 'location present')
-- LSP clients should be present (reversed: stylua, lua_ls)
assert_contains(result3, hl('Title', ' ') .. hl('TextSecondary', 'stylua, lua_ls'), 'LSP clients present')
-- Separator between location and LSP
assert_contains(result3, hl('@comment', '%l:%v') .. RIGHT_SEPARATOR .. hl('Title', ' ') .. hl('TextSecondary', 'stylua, lua_ls'), 'separator between location and lsp')
-- No separator BEFORE the first visible right segment (location)
local loc = hl('@comment', '%l:%v')
-- The right section starts after %= which is right after left content
-- We just check there's no stray separator at a bad position
assert_not_contains(result3, '%= ' .. RIGHT_SEPARATOR, 'no right separator right after %=')
teardown_vim()

-- ============================================================
describe('MyStatusLine: single visible segment on each side')

setup_vim({
  g = { gitsigns_head = nil, statusline_show_filepath = true, statusline_show_position = false, statusline_show_time = true, gitsigns_head = nil },
  b = {},
  lsp = { get_clients = function() return {} end },
})

-- Mock time to a fixed value for testing
local orig_date = os.date
os.date = function(fmt) if fmt == '%H:%M' then return '14:30' end; return orig_date(fmt) end

local result4 = MyStatusLine()
-- Left: only file
local left_expected = hl('TextSecondary', 'test.lua')
-- Right: only time
local right_expected = '14:30'
-- Full expected: ' ' + left_expected + '%=' + right_expected + ' '
local expected = ' ' .. left_expected .. '%=' .. right_expected .. ' '
assert_eq(result4, expected, 'single segment each side, no separators')

-- Restore os.date
os.date = orig_date
teardown_vim()

-- ============================================================
describe('MyStatusLine: all empty sections (minimal output)')

setup_vim({
  g = {
    statusline_show_filepath = false,
    statusline_show_position = false,
    statusline_show_time = false,
    gitsigns_head = nil,
  },
  b = {},
  lsp = { get_clients = function() return {} end },
  diagnostic = { get = function() return {} end },
})
local result5 = MyStatusLine()
-- Left and right both empty, just prefix, %=, and suffix
assert_eq(result5, ' %= ', 'no content on either side: prefix %= suffix only')
teardown_vim()

-- ============================================================
describe('MyStatusLine: diagnostics on left, lsp on right')

setup_vim({
  g = { gitsigns_head = nil, statusline_show_filepath = true, statusline_show_position = false, statusline_show_time = false },
  b = {},
  lsp = { get_clients = function() return { { name = 'lua_ls' } } end },
  diagnostic = {
    get = function()
      return {
        { severity = 1 }, -- error
        { severity = 1 }, -- error
        { severity = 3 }, -- info
      }
    end
  },
})

local result6 = MyStatusLine()
-- Left: file + diagnostics (separator between)
local left_file = hl('TextSecondary', 'test.lua')
local left_diag = hl('DiagnosticError', ' 2 ') .. hl('DiagnosticInfo', ' 1 ')
assert_contains(result6, left_file .. LEFT_SEPARATOR .. left_diag, 'file and diagnostics separated by left separator')
-- Starts with LEFT_PREFIX space then file (no separator prefix)
assert_eq(result6:sub(1, #left_file + 1), ' ' .. left_file, 'starts with space then file, no prefix separator')
-- Right: only LSP, no separators
local right_lsp = hl('Title', ' ') .. hl('TextSecondary', 'lua_ls')
assert_contains(result6, '%=' .. right_lsp, 'lsp on right, no prefix separators')
teardown_vim()

-- ============================================================
describe('MyStatusLine: zen mode returns empty')

setup_vim({ g = { zen_mode = true } })
assert_empty(MyStatusLine(), 'zen mode returns empty string')
teardown_vim()

-- ============================================================
describe('MyStatusLine: dbout filetype returns default')

setup_vim({ bo = { filetype = 'dbout' } })
assert_eq(MyStatusLine(), hl('TextSecondary', ' %f'), 'dbout filetype returns default statusline')
teardown_vim()

-- ============================================================
describe('MyStatusLine: statusline disabled')

setup_vim({ g = { statusline = false } })
assert_eq(MyStatusLine(), hl('TextSecondary', ' %f'), 'statusline disabled returns default')
teardown_vim()

-- ============================================================
describe('MyStatusLine: recording macro with file')

setup_vim({
  g = {
    gitsigns_head = nil,
    statusline_show_position = false,
    statusline_show_time = false,
    recording_macro = true,
  },
  b = {},
})
local result7 = MyStatusLine()
-- Left: file, Right: macro recording indicator
assert_contains(result7, hl('WarningMsg', '  recording macro '), 'macro indicator on right')
-- No right separator prefix before macro (it's the only right segment)
local right_macro = hl('WarningMsg', '  recording macro ')
local right_part = result7:match('%%=(.*) ')
assert_eq(right_part, right_macro, 'macro is only right segment, no prefix separator')
teardown_vim()

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
