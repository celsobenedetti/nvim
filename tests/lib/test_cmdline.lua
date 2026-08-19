--- Tests for lib.cmdline cmdline helpers (fzf-tab on `<Tab>`).
--- Run with: luajit tests/lib/test_cmdline.lua
---
--- Mocks the neovim globals the module depends on.

package.path = './lua/?.lua;' .. package.path

local mock = {}

function mock.setup(tbl)
  for k, v in pairs(tbl) do
    rawset(_G, k, v)
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
local state = {
  cmdtype = ':', -- getcmdtype()
  line = 'e **', -- getcmdline()
  dirs = {}, -- paths that isdirectory() reports as existing
}
local fed = {} -- keys passed to nvim_feedkeys
local scheduled = {} -- callbacks passed to vim.schedule
local cmd_e_calls = {} -- args of vim.cmd.e()
local files_opts = nil -- opts of the mocked fzf-lua files() call

local cmd_mock = setmetatable({}, {
  __call = function(_, cmdstr)
    cmd_e_calls[#cmd_e_calls + 1] = cmdstr
  end,
})

local vim_mock = {
  fn = {
    getcmdtype = function()
      return state.cmdtype
    end,
    getcmdline = function()
      return state.line
    end,
    expand = function(s)
      if s:sub(1, 1) == '~' then
        return '/home/u' .. s:sub(2)
      end
      return s
    end,
    isdirectory = function(s)
      return state.dirs[s] and 1 or 0
    end,
    fnamemodify = function(s, mod)
      if mod == ':p' and not s:match('^/') then
        return '/cwd/' .. s
      end
      return s
    end,
    fnameescape = function(s)
      return s:gsub(' ', '\\ ')
    end,
  },
  uv = {
    cwd = function()
      return '/cwd'
    end,
  },
  api = {
    nvim_feedkeys = function(keys, _, _)
      fed[#fed + 1] = keys
    end,
    nvim_replace_termcodes = function(s)
      return s
    end,
  },
  schedule = function(fn)
    scheduled[#scheduled + 1] = fn
  end,
  cmd = cmd_mock,
}

-- fzf-lua mocks, injected before running the scheduled picker launch.
local fzf_lua_mock = {
  files = function(opts)
    files_opts = opts
  end,
}
local lib_fzf_mock = {
  e = function(opts)
    return opts
  end,
  fd_files_dirs_cmd = function()
    return 'fd --type f --type d'
  end,
  selected_path = function(selected, opts)
    return '/a/b/' .. selected[1]
  end,
}

mock.setup({ vim = vim_mock })

local function reset()
  state.cmdtype = ':'
  state.line = 'e **'
  state.dirs = {}
  fed = {}
  scheduled = {}
  cmd_e_calls = {}
  files_opts = nil
  package.loaded['lib.cmdline'] = nil
end

local function reload_cmdline()
  package.loaded['lib.cmdline'] = nil
  return require('lib.cmdline')
end

-- ============================================================
describe('lib.cmdline: is_fzf_tab')

reset()
local cmdline = reload_cmdline()
assert_eq(cmdline.is_fzf_tab('e **'), true, 'ends with **')
assert_eq(cmdline.is_fzf_tab('e /a/b/**'), true, 'path before **')
assert_eq(cmdline.is_fzf_tab('**'), true, 'bare **')
assert_eq(cmdline.is_fzf_tab('e ** '), false, 'trailing space is not a trigger')
assert_eq(cmdline.is_fzf_tab('e **/x'), false, '** not at the end')
assert_eq(cmdline.is_fzf_tab('e foo'), false, 'no star')
assert_eq(cmdline.is_fzf_tab(''), false, 'empty line')

-- ============================================================
describe('lib.cmdline: parse')

reset()
cmdline = reload_cmdline()

-- bare `**` searches the cwd; the command is preserved
local parsed = cmdline.parse('e **')
assert_eq(parsed.cmd, 'e', 'command kept for bare **')
assert_eq(parsed.dir, '', 'bare ** searches the cwd')

parsed = cmdline.parse('e /a/b/**')
assert_eq(parsed.cmd, 'e', 'command kept')
assert_eq(parsed.dir, '/a/b', 'absolute path, trailing slash dropped')

-- multi-word commands are kept in full
parsed = cmdline.parse('Grep query **')
assert_eq(parsed.cmd, 'Grep query', 'multi-word command kept')
assert_eq(parsed.dir, '', 'bare ** searches the cwd')

parsed = cmdline.parse('e src/**')
assert_eq(parsed.cmd, 'e', 'command kept')
assert_eq(parsed.dir, 'src', 'relative path')

parsed = cmdline.parse('vsplit foo/**')
assert_eq(parsed.cmd, 'vsplit', 'single word command')
assert_eq(parsed.dir, 'foo', 'path after any command')

parsed = cmdline.parse('e ~/code/x/**')
assert_eq(parsed.dir, '~/code/x', 'tilde path kept raw (expanded later)')

parsed = cmdline.parse('e /**')
assert_eq(parsed.dir, '/', 'root dir keeps its slash')

parsed = cmdline.parse('**')
assert_eq(parsed.cmd, '', 'bare ** has no command')
assert_eq(parsed.dir, '', 'bare ** searches the cwd')

assert_eq(cmdline.parse('e **/x'), nil, '** not at the end')
assert_eq(cmdline.parse('e foo'), nil, 'no **')
assert_eq(cmdline.parse(''), nil, 'empty line')

-- ============================================================
describe('lib.cmdline: search_root')

reset()
cmdline = reload_cmdline()
assert_eq(cmdline.search_root(''), '/cwd', 'empty dir searches the cwd')

state.dirs['/a/b'] = true
assert_eq(cmdline.search_root('/a/b'), '/a/b', 'existing absolute dir')

state.dirs['src'] = true
assert_eq(cmdline.search_root('src'), '/cwd/src', 'relative dir made absolute')

assert_eq(cmdline.search_root('/nope'), nil, 'missing dir -> nil')

-- ============================================================
describe('lib.cmdline: fzf_tab decision')

-- `:e **` searches the cwd and launches the picker
reset()
cmdline = reload_cmdline()
cmdline.fzf_tab()
assert_eq(#fed, 1, 'cancels the cmdline')
assert_eq(fed[1], '<C-c>', 'cancels via <C-c>')
assert_eq(#scheduled, 1, 'schedules the picker launch')

-- `:e /a/b/**` with an existing dir launches the picker
reset()
cmdline = reload_cmdline()
state.line = 'e /a/b/**'
state.dirs['/a/b'] = true
cmdline.fzf_tab()
assert_eq(#scheduled, 1, 'schedules for existing dir')
assert_eq(fed[1], '<C-c>', 'cancels the cmdline')

-- `:e /nope/**` with a missing dir falls back to native completion
reset()
cmdline = reload_cmdline()
state.line = 'e /nope/**'
cmdline.fzf_tab()
assert_eq(#scheduled, 0, 'does not launch for missing dir')
assert_eq(fed[1], '<C-z>', 'falls back to wildcharm completion')

-- line without `**` falls back
reset()
cmdline = reload_cmdline()
state.line = 'e foo'
cmdline.fzf_tab()
assert_eq(#scheduled, 0, 'does not launch without **')
assert_eq(fed[1], '<C-z>', 'falls back to wildcharm completion')

-- search cmdline (type `/`) is never hijacked
reset()
cmdline = reload_cmdline()
state.cmdtype = '/'
state.line = 'foo**'
cmdline.fzf_tab()
assert_eq(#scheduled, 0, 'search lines are left alone')
assert_eq(fed[1], '<C-z>', 'falls back to wildcharm completion')

-- ============================================================
describe('lib.cmdline: picker launch + enter action')

-- `:e **` -> files picker rooted at cwd; enter runs `:e <full path>`
reset()
cmdline = reload_cmdline()
cmdline.fzf_tab()
assert_eq(#scheduled, 1, 'picker scheduled')

mock.setup({ lib = { fzf = lib_fzf_mock } })
package.loaded['fzf-lua'] = fzf_lua_mock
scheduled[1]()
assert_eq(files_opts.cwd, '/cwd', 'picker rooted at the cwd')
assert_eq(files_opts.cmd, 'fd --type f --type d', 'picker lists files and dirs')
assert_eq(files_opts.prompt, 'e ** > ', 'prompt shows the typed line')

-- enter with a file selection runs `:e <path>`
files_opts.actions['enter']({ 'file.txt' }, {})
assert_eq(cmd_e_calls[1], 'e /a/b/file.txt', 'enter edits the selected file')

-- the command is preserved: `:Grep query **` runs `:Grep query <path>`
reset()
cmdline = reload_cmdline()
state.line = 'Grep query **'
cmdline.fzf_tab()
scheduled[1]()
assert_eq(files_opts.prompt, 'Grep query ** > ', 'prompt shows the typed line')
files_opts.actions['enter']({ 'file.txt' }, {})
assert_eq(cmd_e_calls[1], 'Grep query /a/b/file.txt', 'enter keeps the user command')

-- `:e /a/b/**` keeps `e` and the typed dir
reset()
cmdline = reload_cmdline()
state.line = 'e /a/b/**'
state.dirs['/a/b'] = true
cmdline.fzf_tab()
scheduled[1]()
assert_eq(files_opts.cwd, '/a/b', 'picker rooted at the typed dir')
assert_eq(files_opts.prompt, 'e /a/b/** > ', 'prompt shows the typed line')
files_opts.actions['enter']({ 'file.txt' }, {})
assert_eq(cmd_e_calls[1], 'e /a/b/file.txt', 'enter rebuilds the command with the selection')

-- a path with spaces is escaped
reset()
cmdline = reload_cmdline()
state.line = 'e /a/b/**'
state.dirs['/a/b'] = true
cmdline.fzf_tab()
scheduled[1]()
files_opts.actions['enter']({ 'my file.txt' }, {})
assert_eq(cmd_e_calls[1], 'e /a/b/my\\ file.txt', 'enter escapes spaces')

-- ============================================================
io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))

if tests_passed ~= tests_run then
  os.exit(1)
end
