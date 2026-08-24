--- Headless integration test: buffers created by after/plugin/cmd-output.lua
--- (filetype 'cmd-output', named `[cmd] <cmd>`) must render a winbar of the
--- shape `<icon> cmd > <cmd>` instead of the empty bar nofile buffers get.
---
--- Run with: nvim --headless -u NONE -l tests/winbar/test_cmd_output_winbar.lua
--- (run from the repo root; loads the real after/plugin/winbar.lua)

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
-- Load the real winbar plugin with minimal globals (it only needs `config`
-- at load time; `lib` is referenced lazily inside render functions).
_G.config = { icons = {} }
dofile(repo_root .. '/after/plugin/winbar.lua')

-- The cmd-output branch returns plain text through lib.strings.hl; stub it
-- the way the real env provides it.
_G.lib = { strings = {
  hl = function(_, text)
    return text
  end,
} }

local tests_run = 0
local tests_passed = 0

local function ok(cond, msg)
  tests_run = tests_run + 1
  if cond then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n', msg))
  end
end

--- Mimic what after/plugin/cmd-output.lua's show_output() builds for a
--- finished capture.
local function make_cmd_output_buffer(cmd)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'out' })
  vim.api.nvim_buf_set_name(buf, '[cmd] ' .. cmd)
  vim.bo[buf].filetype = 'cmd-output'
  return buf
end

local win = vim.api.nvim_get_current_win()

-- Basic case: command recovered from the buffer name, separated by >.
local buf = make_cmd_output_buffer('rg -n foo')
vim.api.nvim_win_set_buf(win, buf)
vim.g.statusline_winid = win
local bar = vim.fn.eval('v:lua.get_winbar()')
ok(bar:find('^ ', 1) ~= nil, 'winbar leads with a leading space/icon')
ok(bar:find('cmd', 1, true) ~= nil, 'winbar mentions cmd')
ok(bar:find('rg -n foo', 1, true) ~= nil, 'winbar renders the full command')
ok(bar:find('^ ', 1) ~= nil and #bar < 40, 'nothing else leaks into the bar')
ok(vim.bo[buf].filetype == 'cmd-output', 'sanity: filetype is cmd-output')

-- A literal % in the command must be doubled, not interpreted as a
-- statusline item.
buf = make_cmd_output_buffer('echo 100% done')
vim.api.nvim_win_set_buf(win, buf)
ok(vim.fn.eval('v:lua.get_winbar()'):find('100%% done', 1, true) ~= nil, '% in command is escaped')

-- A buffer named like a cmd-output buffer but with another filetype falls
-- through to the generic rendering (empty for nofile).
buf = make_cmd_output_buffer('ls -la')
vim.bo[buf].filetype = 'man'
vim.api.nvim_win_set_buf(win, buf)
ok(vim.fn.eval('v:lua.get_winbar()') == '', 'other filetypes do not get the cmd bar')

io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
