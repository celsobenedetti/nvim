--- Headless integration test: fugitive's :Gclog fills the quickfix list with
--- log entries; the winbar QuickFixCmdPost autocmd must stamp the qf buffer
--- with its own breadcrumb winbar (` qf >  git >  git log`) and clear it
--- again when a non-fugitive quickfix command (e.g. :grep) reuses that buffer.
---
--- Fugitive fires `QuickFixCmdPost cfugitive-log` for :Gclog (see
--- s:QuickfixStream in autoload/fugitive.vim: `event = 'c' . 'fugitive-' .
--- a:event`, with a:event == 'log'). We simulate it with :doautocmd so the
--- test doesn't depend on the fugitive plugin being installed; the event name
--- is verified against fugitive's source.
---
--- Run with: nvim --headless -u NONE -l tests/winbar/test_gclog_winbar.lua
--- (run from the repo root; loads the real after/plugin/winbar.lua)

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
-- Load the real winbar plugin with minimal globals (it only needs `config`
-- at load time; `lib` is referenced lazily inside render functions).
_G.config = { icons = {} }
dofile(repo_root .. '/after/plugin/winbar.lua')

-- get_winbar()'s vim.b.winbar branch renders through lib.strings.hl; stub it
-- the way the real env provides it (the float test never reaches that path).
_G.lib = { strings = { hl = function(_, text) return text end } }

local FUGITIVE_LOG_WINBAR = ' qf >  git >  git log'

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

-- Open a quickfix list and its window the way :Gclog leaves them: qf window
-- open, but fugitive has switched back to the invoking window.
vim.fn.setqflist({ { filename = 'a.txt', lnum = 1, text = 'ed36539 two' } }, 'r')
vim.cmd('copen')
vim.cmd('wincmd p') -- back to the invoking window, as fugitive does

local qf_win = nil
for _, info in ipairs(vim.fn.getwininfo()) do
  if info.quickfix == 1 then
    qf_win = info.winid
  end
end
assert(qf_win, 'quickfix window must exist after copen')
local qf_buf = vim.api.nvim_win_get_buf(qf_win)
ok(vim.bo[qf_buf].buftype == 'quickfix', 'qf buffer has quickfix buftype')
ok(vim.b[qf_buf].winbar == nil, 'qf buffer starts without a winbar override')

-- :Gclog → fugitive runs `doautocmd QuickFixCmdPost cfugitive-log`
vim.cmd('doautocmd QuickFixCmdPost cfugitive-log')
ok(vim.b[qf_buf].winbar == FUGITIVE_LOG_WINBAR, 'cfugitive-log stamps the git-log winbar')

-- The vim.b.winbar override in get_winbar() surfaces it when the qf buffer is
-- current (which is the only window whose bar we can see anyway).
vim.api.nvim_set_current_win(qf_win)
vim.g.statusline_winid = qf_win
local bar = vim.fn.eval('v:lua.get_winbar()')
ok(bar:find('qf', 1, true) ~= nil, 'winbar renders the qf override')
ok(bar:find('git log', 1, true) ~= nil, 'winbar mentions git log')

-- A later non-fugitive quickfix command (e.g. :grep) reuses the same qf
-- buffer; the override must be cleared, not left stale.
vim.cmd('doautocmd QuickFixCmdPost grep')
ok(vim.b[qf_buf].winbar == nil, 'a later :grep clears the stale git-log winbar')

-- :Gllog's location list is a different event and must not stamp the qf buffer.
vim.cmd('doautocmd QuickFixCmdPost lfugitive-log')
ok(vim.b[qf_buf].winbar == nil, 'Gllog (location list) leaves the qf buffer alone')

io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
