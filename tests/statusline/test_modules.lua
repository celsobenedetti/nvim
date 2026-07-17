--- Tests for statusline module segment functions
--- Run with: luajit tests/statusline/test_modules.lua
---
--- These test the segment-producing functions in isolation by mocking
--- the neovim globals they depend on.

-- {{{ Mock infrastructure
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

-- Minimal hl compatible with the real one
local function hl(group, text)
  return '%#' .. group .. '#' .. text .. '%*'
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

local function assert_not_empty(got, msg)
  tests_run = tests_run + 1
  if #got > 0 then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n  expected non-empty, got empty string\n', msg))
  end
end

local function describe(label)
  io.write('\n--- ' .. label .. '\n')
end
-- }}}

-- ============================================================
-- Mock shared vim.g globals used by multiple functions
local MOCK_ICONS = {
  git = {
    branch = ' ',
    ahead = '',
    behind = '',
    added = ' +',
    modified = ' ~',
    removed = ' -',
  },
  lsp = ' ',
  format = ' ',
  diagnostics = {
    error = ' ',
    warn = ' ',
    info = ' ',
    hint = ' ',
  },
}

local MOCK_HL = {
  text = {
    highlight = 'Title',
    secondary = 'TextSecondary',
    subtext = '@comment',
    warn = 'WarningMsg',
  },
  warn = 'LspDiagnosticsVirtualTextWarning',
}

-- ============================================================
describe('_git_branch')

do
  -- Replica of _git_branch from the plugin
  local function _git_branch()
    if not vim.g.gitsigns_head or #vim.g.gitsigns_head == 0 then
      return ''
    end

    return hl('Title', ' ') .. hl('TextSecondary', vim.g.gitsigns_head or '')
  end

  -- Test: no branch set
  mock.setup({ vim = { g = { gitsigns_head = nil, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_git_branch(), 'no gitsigns_head set')
  mock.teardown({ 'vim' })

  -- Test: empty branch
  mock.setup({ vim = { g = { gitsigns_head = '', icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_git_branch(), 'empty gitsigns_head')
  mock.teardown({ 'vim' })

  -- Test: branch set
  mock.setup({ vim = { g = { gitsigns_head = 'main', icons = MOCK_ICONS, hl = MOCK_HL } } })
  local expected = hl('Title', ' ') .. hl('TextSecondary', 'main')
  assert_eq(_git_branch(), expected, 'branch "main"')
  mock.teardown({ 'vim' })

  -- Test: branch with slash
  mock.setup({ vim = { g = { gitsigns_head = 'feature/foo', icons = MOCK_ICONS, hl = MOCK_HL } } })
  local expected2 = hl('Title', ' ') .. hl('TextSecondary', 'feature/foo')
  assert_eq(_git_branch(), expected2, 'branch "feature/foo"')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_branch_sync_status')

do
  -- Replica of _branch_sync_status from plugin
  local function _branch_sync_status()
    local branch_status = ''
    if vim.g.branch_commits_behind_origin and vim.g.branch_commits_behind_origin > 0 then
      branch_status = ' ' .. '' .. vim.g.branch_commits_behind_origin
    end
    if vim.g.branch_commits_ahead_of_origin and vim.g.branch_commits_ahead_of_origin > 0 then
      branch_status = branch_status .. '' .. vim.g.branch_commits_ahead_of_origin
    end

    if #branch_status == 0 then
      return ''
    end
    return hl('TextSecondary', branch_status)
  end

  -- Test: no counts set
  mock.setup({ vim = { g = { branch_commits_behind_origin = nil, branch_commits_ahead_of_origin = nil, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_branch_sync_status(), 'no counts set')
  mock.teardown({ 'vim' })

  -- Test: zero values
  mock.setup({ vim = { g = { branch_commits_behind_origin = 0, branch_commits_ahead_of_origin = 0, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_branch_sync_status(), 'zero counts')
  mock.teardown({ 'vim' })

  -- Test: behind only
  mock.setup({ vim = { g = { branch_commits_behind_origin = 3, branch_commits_ahead_of_origin = 0, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_branch_sync_status(), hl('TextSecondary', ' 3'), '3 behind, 0 ahead')
  mock.teardown({ 'vim' })

  -- Test: ahead only
  mock.setup({ vim = { g = { branch_commits_behind_origin = 0, branch_commits_ahead_of_origin = 5, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_branch_sync_status(), hl('TextSecondary', '5'), '0 behind, 5 ahead')
  mock.teardown({ 'vim' })

  -- Test: both ahead and behind
  mock.setup({ vim = { g = { branch_commits_behind_origin = 2, branch_commits_ahead_of_origin = 1, icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_branch_sync_status(), hl('TextSecondary', ' 21'), '2 behind, 1 ahead')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_file')

do
  local function _file()
    if not vim.g.statusline_show_filepath then
      return ''
    end
    vim.b.relative_file = vim.fn.expand('%:.')
    local icon = ''
    -- devicons skipped for simplicity; mock would return nil

    local file = hl('TextSecondary', vim.b.relative_file)
    return icon .. '' .. file
  end

  -- Test: show_filepath disabled
  mock.setup({
    vim = {
      g = { statusline_show_filepath = false, hl = MOCK_HL },
      b = {},
      fn = { expand = function() return 'test.lua' end },
    }
  })
  assert_empty(_file(), 'statusline_show_filepath = false')
  mock.teardown({ 'vim' })

  -- Test: show_filepath enabled
  mock.setup({
    vim = {
      g = { statusline_show_filepath = true, hl = MOCK_HL },
      b = {},
      fn = { expand = function() return 'after/plugin/statusline.lua' end },
    }
  })
  local expected = hl('TextSecondary', 'after/plugin/statusline.lua')
  assert_eq(_file(), expected, 'filepath shown')
  mock.teardown({ 'vim' })

  -- Test: empty relative path (no file)
  mock.setup({
    vim = {
      g = { statusline_show_filepath = true, hl = MOCK_HL },
      b = {},
      fn = { expand = function() return '' end },
    }
  })
  assert_eq(_file(), hl('TextSecondary', ''), 'empty relative path')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_git_status')

do
  local function _git_status()
    local status = vim.b.gitsigns_status_dict or {}
    local added = status.added or 0
    local modified = status.changed or 0
    local removed = status.removed or 0

    if added == 0 and modified == 0 and removed == 0 then
      return ''
    end

    local result = ''
    if added > 0 then
      result = result .. hl('GitSignsAdd', ' +' .. added)
    end
    if modified > 0 then
      result = result .. hl('GitSignsChange', ' ~' .. modified)
    end
    if removed > 0 then
      result = result .. hl('GitSignsDelete', ' -' .. removed)
    end
    return result
  end

  -- Test: no status dict
  mock.setup({ vim = { b = { gitsigns_status_dict = nil }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_git_status(), 'no gitsigns_status_dict')
  mock.teardown({ 'vim' })

  -- Test: all zero
  mock.setup({ vim = { b = { gitsigns_status_dict = { added = 0, changed = 0, removed = 0 } }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_git_status(), 'all zeros')
  mock.teardown({ 'vim' })

  -- Test: some changes
  mock.setup({ vim = { b = { gitsigns_status_dict = { added = 3, changed = 2, removed = 1 } }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  local expected = hl('GitSignsAdd', ' +3') .. hl('GitSignsChange', ' ~2') .. hl('GitSignsDelete', ' -1')
  assert_eq(_git_status(), expected, '3 added, 2 modified, 1 removed')
  mock.teardown({ 'vim' })

  -- Test: only added
  mock.setup({ vim = { b = { gitsigns_status_dict = { added = 5, changed = 0, removed = 0 } }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_git_status(), hl('GitSignsAdd', ' +5'), 'only added')
  mock.teardown({ 'vim' })

  -- Test: only modified
  mock.setup({ vim = { b = { gitsigns_status_dict = { added = 0, changed = 7, removed = 0 } }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_git_status(), hl('GitSignsChange', ' ~7'), 'only modified')
  mock.teardown({ 'vim' })

  -- Test: only removed
  mock.setup({ vim = { b = { gitsigns_status_dict = { added = 0, changed = 0, removed = 2 } }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_eq(_git_status(), hl('GitSignsDelete', ' -2'), 'only removed')
  mock.teardown({ 'vim' })

  -- Test: status is empty table
  mock.setup({ vim = { b = { gitsigns_status_dict = {} }, g = { icons = MOCK_ICONS, hl = MOCK_HL } } })
  assert_empty(_git_status(), 'empty status dict')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_diagnostics')

do
  local function _diagnostics(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local count = { 0, 0, 0, 0 }
    for _, diagnostic in pairs(vim.diagnostic.get(bufnr)) do
      count[diagnostic.severity] = count[diagnostic.severity] + 1
    end
    local result = ''
    if count[1] > 0 then result = result .. hl('DiagnosticError', ' ' .. tostring(count[1]) .. ' ') end
    if count[2] > 0 then result = result .. hl('DiagnosticWarn', ' ' .. tostring(count[2]) .. ' ') end
    if count[3] > 0 then result = result .. hl('DiagnosticInfo', ' ' .. tostring(count[3]) .. ' ') end
    if count[4] > 0 then result = result .. hl('DiagnosticHint', ' ' .. tostring(count[4]) .. ' ') end
    return result
  end

  -- Test: no diagnostics
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      diagnostic = { get = function() return {} end },
    }
  })
  assert_empty(_diagnostics(), 'no diagnostics')
  mock.teardown({ 'vim' })

  -- Test: errors only
  local diagnostic_error = { severity = 1 }
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      diagnostic = { get = function() return { diagnostic_error, diagnostic_error } end },
    }
  })
  assert_eq(_diagnostics(), hl('DiagnosticError', ' 2 '), '2 errors')
  mock.teardown({ 'vim' })

  -- Test: all severities
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      diagnostic = {
        get = function()
          return {
            { severity = 1 },
            { severity = 2 },
            { severity = 2 },
            { severity = 3 },
            { severity = 4 },
            { severity = 4 },
            { severity = 4 },
          }
        end
      },
    }
  })
  local expected = hl('DiagnosticError', ' 1 ')
    .. hl('DiagnosticWarn', ' 2 ')
    .. hl('DiagnosticInfo', ' 1 ')
    .. hl('DiagnosticHint', ' 3 ')
  assert_eq(_diagnostics(), expected, 'mixed severities: 1 error, 2 warn, 1 info, 3 hint')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_lsps')

do
  local function _lsps()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if next(clients) == nil then
      return ''
    end

    local c = {}
    for _, client in pairs(clients) do
      table.insert(c, client.name)
    end
    return hl('Title', ' ') .. hl('TextSecondary', table.concat(vim.fn.reverse(c), ', '))
  end

  -- Test: no clients
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      lsp = { get_clients = function() return {} end },
      fn = { reverse = function(t) local r = {}; for i=#t,1,-1 do r[#r+1]=t[i] end; return r end },
    }
  })
  assert_empty(_lsps(), 'no LSP clients')
  mock.teardown({ 'vim' })

  -- Test: single client
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      lsp = { get_clients = function() return { { name = 'lua_ls' } } end },
      fn = { reverse = function(t) local r = {}; for i=#t,1,-1 do r[#r+1]=t[i] end; return r end },
    }
  })
  assert_eq(_lsps(), hl('Title', ' ') .. hl('TextSecondary', 'lua_ls'), 'single LSP')
  mock.teardown({ 'vim' })

  -- Test: multiple clients (reverse order)
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
      lsp = { get_clients = function() return { { name = 'lua_ls' }, { name = 'stylua' } } end },
      fn = { reverse = function(t) local r = {}; for i=#t,1,-1 do r[#r+1]=t[i] end; return r end },
    }
  })
  assert_eq(_lsps(), hl('Title', ' ') .. hl('TextSecondary', 'stylua, lua_ls'), 'multiple LSPs reversed')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_formatters')

do
  local function _formatters()
    local ok, conform = pcall(require, 'conform')
    if not ok then
      return ''
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local formatters = conform.list_formatters_for_buffer(bufnr)
    local c = {}
    for _, formatter in pairs(formatters) do
      table.insert(c, formatter)
    end
    local result = table.concat(c, ', ')
    if #result == 0 then
      return ''
    end

    return hl('Title', ' ') .. hl('TextSecondary', result)
  end

  -- Helper to set up conform mock and clear the require cache
  local function setup_conform(formatters_for_buffer)
    package.loaded['conform'] = nil
    package.preload['conform'] = function()
      return {
        list_formatters_for_buffer = function() return formatters_for_buffer end,
      }
    end
  end

  -- Test: conform not available
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
    }
  })
  package.loaded['conform'] = nil
  package.preload['conform'] = nil
  assert_empty(_formatters(), 'conform not installed')
  mock.teardown({ 'vim' })

  -- Test: no formatters for buffer
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
    }
  })
  setup_conform({})
  assert_empty(_formatters(), 'no formatters for buffer')
  mock.teardown({ 'vim' })

  -- Test: one formatter
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
    }
  })
  setup_conform({ 'stylua' })
  assert_eq(_formatters(), hl('Title', ' ') .. hl('TextSecondary', 'stylua'), 'one formatter')
  mock.teardown({ 'vim' })

  -- Test: multiple formatters
  mock.setup({
    vim = {
      g = { icons = MOCK_ICONS, hl = MOCK_HL },
      api = { nvim_get_current_buf = function() return 1 end },
    }
  })
  setup_conform({ 'stylua', 'prettier' })
  assert_eq(_formatters(), hl('Title', ' ') .. hl('TextSecondary', 'stylua, prettier'), 'multiple formatters')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_macro (recording macro indicator)')

do
  local function _macro()
    if not vim.g.recording_macro then
      return ''
    end
    return hl('WarningMsg', '  recording macro ')
  end

  mock.setup({ vim = { g = { recording_macro = false, hl = MOCK_HL } } })
  assert_empty(_macro(), 'not recording')
  mock.teardown({ 'vim' })

  mock.setup({ vim = { g = { recording_macro = true, hl = MOCK_HL } } })
  assert_eq(_macro(), hl('WarningMsg', '  recording macro '), 'recording')
  mock.teardown({ 'vim' })

  mock.setup({ vim = { g = { recording_macro = nil, hl = MOCK_HL } } })
  assert_empty(_macro(), 'recording_macro nil')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_terminal (terminal buffer indicator)')

do
  local function _terminal()
    if not vim.b.term then
      return ''
    end
    return hl('MiniStatuslineModeOther', '   terminal ')
  end

  mock.setup({ vim = { b = { term = nil }, g = { hl = MOCK_HL } } })
  assert_empty(_terminal(), 'not a terminal buffer')
  mock.teardown({ 'vim' })

  mock.setup({ vim = { b = { term = true }, g = { hl = MOCK_HL } } })
  assert_not_empty(_terminal(), 'terminal buffer')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_location (cursor position)')

do
  local function _location()
    if not vim.g.statusline_show_position then
      return ''
    end
    return hl('@comment', '%l:%v')
  end

  mock.setup({ vim = { g = { statusline_show_position = false, hl = MOCK_HL } } })
  assert_empty(_location(), 'position hidden')
  mock.teardown({ 'vim' })

  mock.setup({ vim = { g = { statusline_show_position = true, hl = MOCK_HL } } })
  assert_eq(_location(), hl('@comment', '%l:%v'), 'position shown')
  mock.teardown({ 'vim' })
end

-- ============================================================
describe('_time')

do
  -- Pure function, no mocks needed
  local function _time()
    return os.date('%H:%M')
  end

  local result = _time()
  tests_run = tests_run + 1
  if type(result) == 'string' and #result == 5 and result:match('%d%d:%d%d') then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: _time expected HH:MM format, got %q\n', result))
  end
end

-- ============================================================
describe('_search_results')

do
  local function _search_results()
    if vim.v.hlsearch == 1 then
      local sinfo = vim.fn.searchcount({ maxcount = 0 })
      local search_stat = sinfo.incomplete > 0 and '[?/?]'
        or sinfo.total > 0 and ('[%s/%s]'):format(sinfo.current, sinfo.total)
        or nil

      if search_stat then
        return hl('@comment', search_stat)
      end
    end
  end

  -- Test: hlsearch = 0
  mock.setup({
    vim = {
      v = { hlsearch = 0 },
      fn = { searchcount = function() return {} end },
      g = { hl = MOCK_HL },
    }
  })
  assert_eq(_search_results(), nil, 'hlsearch = 0 returns nil')
  mock.teardown({ 'vim' })

  -- Test: hlsearch = 1, incomplete
  mock.setup({
    vim = {
      v = { hlsearch = 1 },
      fn = { searchcount = function() return { incomplete = 1, current = 0, total = 0 } end },
      g = { hl = MOCK_HL },
    }
  })
  assert_eq(_search_results(), hl('@comment', '[?/?]'), 'incomplete search')
  mock.teardown({ 'vim' })

  -- Test: hlsearch = 1, total=0 (no matches)
  mock.setup({
    vim = {
      v = { hlsearch = 1 },
      fn = { searchcount = function() return { incomplete = 0, current = 0, total = 0 } end },
      g = { hl = MOCK_HL },
    }
  })
  assert_eq(_search_results(), nil, 'hlsearch=1, total=0 returns nil')
  mock.teardown({ 'vim' })

  -- Test: hlsearch = 1, valid match
  mock.setup({
    vim = {
      v = { hlsearch = 1 },
      fn = { searchcount = function() return { incomplete = 0, current = 2, total = 5 } end },
      g = { hl = MOCK_HL },
    }
  })
  assert_eq(_search_results(), hl('@comment', '[2/5]'), 'hlsearch active, 2/5 matches')
  mock.teardown({ 'vim' })
end

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
