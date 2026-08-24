--- Headless integration test: blink.cmp-style completion floats must not
--- corrupt the home-grown tabline while they open.
---
--- During nvim_open_win Neovim transiently makes the new float the current
--- window of its tabpage (even with enter=false). tabs.lua redraws the tabline
--- on BufEnter/BufWinEnter -- events fired for the float's scratch buffer --
--- so lib.tab.render() can evaluate in that window: fallback_name() resolved
--- nvim_tabpage_get_win() to the float, read its unnamed scratch buffer, and
--- the tab rendered as `[No Name]`, flipping back on the next evaluation
--- (visible flicker of individual tabs whenever the completion menu popped).
--- The same flaw let float buffers break single_buffer_bufnr(), hiding the
--- special (terminal) label of single-buffer tabs while any float was open.
---
--- Run with: nvim --headless -u NONE -l tests/integration/test_tabline_float_flicker.lua
--- (run from the repo root; loads the real lib/tab and after/plugin/tabs.lua)

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
-- PREPEND the repo to 'runtimepath': with -u NONE the live ~/.config/nvim is
-- first on rtp and Neovim's rtp-based Lua loader wins over package.path, so
-- require('lib.*') would silently load the live (unfixed) module
vim.opt.runtimepath:prepend(repo_root)

_G.config = { icons = { code = '', agent = '', git = { git = '' } } }
_G.state = {}
-- lib.tab's SPECIAL_FILETYPES routes terminal tabs through the shared label
_G.get_terminal_label = function(bufnr)
  return ' STUB-TERMINAL-' .. tostring(bufnr)
end
_G.lib = { tab = require('lib.tab') }

dofile(repo_root .. '/after/plugin/tabs.lua')

local tests_run, tests_passed = 0, 0
local function ok(cond, msg)
  tests_run = tests_run + 1
  if cond then
    tests_passed = tests_passed + 1
    io.write('.')
  else
    io.write(string.format('\nFAIL: %s\n', msg))
  end
end

---Open a float the way blink.cmp does: fresh unlisted scratch buffer,
---minimal chrome, enter=false.
---@return integer bufnr
---@return integer winid
local function open_blink_style_float()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].tabstop = 1
  vim.bo[buf].filetype = 'blink-cmp-menu'
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    style = 'minimal',
    width = 30,
    height = 8,
    row = 1,
    col = 1,
    border = 'single',
  })
  return buf, win
end

-- two tabs showing named files, like the reproduction session
local tmp = vim.fn.tempname()
os.remove(tmp)
vim.fn.mkdir(tmp, 'p')
vim.cmd('edit ' .. tmp .. '/fixture_a.lua')
vim.cmd('tabedit ' .. tmp .. '/fixture_b.lua')
vim.cmd('tabnext 1')
local tab1 = vim.api.nvim_list_tabpages()[1]

-- sanity: labels are correct with no floats around
ok(lib.tab.get_name(tab1) == 'fixture_a.lua', 'tab 1 label at rest is fixture_a.lua')

-- Scenario 1: mid-open transient state -- blink's float is the current window
local _, menu_win = open_blink_style_float()
vim.api.nvim_set_current_win(menu_win)
ok(
  lib.tab.get_name(tab1) == 'fixture_a.lua',
  'label ignores the transiently-current float (was [No Name])'
)
local rendered = vim.api.nvim_eval('v:lua.lib.tab.render()')
ok(rendered:find('fixture_a%.lua', 1, false) ~= nil, 'render shows the real label during the transient')
ok(rendered:find('[No Name]', 1, true) == nil, 'render never emits [No Name] during the transient')
vim.api.nvim_set_current_win(vim.fn.win_getid(1))

-- Scenario 2: a single-buffer terminal tab keeps its special label while a
-- float is open in it (float buffers must not count toward "several buffers")
vim.cmd('tabnew')
local term_tab = vim.api.nvim_get_current_tabpage()
local tbuf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(term_tab))
-- 'buftype' cannot be set to 'terminal' manually (E474); the special-label
-- lookup in lib.tab is keyed on filetype alone, so faking it is enough
vim.bo[tbuf].filetype = 'terminal'
-- guard: we stamped the fresh tab's own unnamed buffer, not some other tab's
ok(
  vim.api.nvim_buf_get_name(tbuf) == '' and #vim.api.nvim_tabpage_list_wins(term_tab) == 1,
  'scenario targets the fresh single-window tab'
)
ok(
  lib.tab.get_name(term_tab):find('STUB-TERMINAL', 1, true) ~= nil,
  'single-buffer terminal tab gets its special label at rest'
)
local _, float2 = open_blink_style_float()
vim.api.nvim_set_current_win(float2)
ok(
  lib.tab.get_name(term_tab):find('STUB-TERMINAL', 1, true) ~= nil,
  'special label survives a float opening in the tab'
)

io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
