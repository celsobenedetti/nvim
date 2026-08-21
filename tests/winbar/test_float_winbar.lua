--- Headless integration test: the winbar BufWinEnter/WinEnter autocmd must
--- not install a winbar on windows that can't hold one.
---
--- Regression: setting a winbar on a floating window with view height <= 1
--- makes nvim raise E36 "Not enough room" inside the BufWinEnter autocmds,
--- aborting the caller's nvim_open_win — the snacks picker input window
--- (1-line float) and blink.cmp's completion float both hit this, breaking
--- <leader>si and completion.
---
--- Run with: nvim --headless -u NONE -l tests/winbar/test_float_winbar.lua
--- (run from the repo root; loads the real after/plugin/winbar.lua)

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
-- Load the real winbar plugin with minimal globals (it only needs `config`
-- at load time; `lib` is referenced lazily inside render functions).
_G.config = { icons = {} }
dofile(repo_root .. '/after/plugin/winbar.lua')

local WINBAR_EXPR = '%!v:lua.get_winbar()'

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

local function new_float(buf, height)
  local ok_open, win = pcall(vim.api.nvim_open_win, buf, true, {
    relative = 'editor',
    row = 0,
    col = 0,
    width = 40,
    height = height,
    style = 'minimal',
  })
  return ok_open, win
end

-- Scenario 1: 1-line float with a scratch (nofile) buffer — the snacks picker
-- input / blink.cmp completion case. Must open without E36.
local buf = vim.api.nvim_create_buf(false, true)
assert(vim.bo[buf].buftype == 'nofile', 'scratch buffer must be nofile')
local ok_open, win = new_float(buf, 1)
ok(ok_open, '1-line nofile float opens without error (was E36 Not enough room)')
if ok_open then
  ok(vim.wo[win].winbar == '', 'no winbar installed on 1-line nofile float')
  vim.api.nvim_win_close(win, true)
end

-- Scenario 2: 1-line float with a real (non-nofile) buffer — must also open
-- without E36 and without a winbar (too small to hold one).
local file_buf = vim.api.nvim_create_buf(false, false)
ok_open, win = new_float(file_buf, 1)
ok(ok_open, '1-line real-buffer float opens without error')
if ok_open then
  ok(vim.wo[win].winbar == '', 'no winbar installed on 1-line float (view height <= 1)')
  vim.api.nvim_win_close(win, true)
end

-- Scenario 3: tall float with a real buffer — winbar still installed
-- (preserves the pre-regression behavior for e.g. the lazygit float).
ok_open, win = new_float(file_buf, 5)
ok(ok_open, 'tall float opens without error')
if ok_open then
  ok(vim.wo[win].winbar == WINBAR_EXPR, 'winbar installed on tall float')
  vim.api.nvim_win_close(win, true)
end

-- Scenario 4: regular split with a real buffer — winbar installed.
vim.cmd('vsplit')
local split_win = vim.api.nvim_get_current_win()
ok(vim.wo[split_win].winbar == WINBAR_EXPR, 'winbar installed on file split')
vim.cmd('close')

-- Scenario 5: split showing a nofile buffer — no winbar (scratch UI).
local scratch_split = vim.api.nvim_open_win(buf, true, { split = 'below' })
ok(vim.wo[scratch_split].winbar == '', 'no winbar on nofile split')
vim.api.nvim_win_close(scratch_split, true)

io.write(string.format('\n\n%d / %d tests passed\n', tests_passed, tests_run))
os.exit(tests_passed == tests_run and 0 or 1)
