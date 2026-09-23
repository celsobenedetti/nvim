-- Integration test (real nvim, headless): the pi-terminal follow feature in
-- after/plugin/pi.lua tails output in unfocused windows of any terminal running
-- a pi instance, while terminals not running pi are left alone.
-- (The insert-mode exemption pi.lua registers is unit-tested in
-- tests/plugin/test_pi.lua instead: `:startinsert` only takes effect on return
-- to the main loop, so mode() never reflects it under `nvim -l`.)
--
-- pi is stood in for by a copy of bash named `pi`: what makes a terminal a pi
-- terminal is the job command / process name (state.pi.is_running), and a shell
-- copy gives us a pi-named process we can drive output from.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

-- Repo root on rtp so `require('lib.*')` resolves (Makefile runs us from there).
local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)

-- Globals the plugin files expect from the live config.
_G.state = {}
_G.config = { keys = { ['<C-/>'] = '<C-\\>' } }
_G.lib = {
  term = require('lib.term'),
  buffers = {
    get_valid_bufs = function()
      return {}
    end,
    focus = function() end,
  },
}

-- Load the real plugin wiring under test (defines the autocmds).
vim.cmd('luafile ' .. cwd .. '/after/plugin/agents.lua')
vim.cmd('luafile ' .. cwd .. '/after/plugin/terminal.lua')
vim.cmd('luafile ' .. cwd .. '/after/plugin/pi.lua')

local fake_pi_dir = vim.fn.tempname()
vim.fn.mkdir(fake_pi_dir, 'p')
local fake_pi = fake_pi_dir .. '/pi'
vim.fn.writefile(vim.fn.readblob(vim.fn.exepath('bash')), fake_pi, 'b')
vim.fn.setfperm(fake_pi, 'rwxr-xr-x')
vim.env.PATH = fake_pi_dir .. ':' .. vim.env.PATH

local function wait_for(cond, msg)
  assert(vim.wait(5000, cond, 50), msg)
end

--- An unfocused window showing `buf` (the follow target must not be current).
--- Assumes a single vertical split: current window keeps focus, the other one
--- is the follower.
local function find_follower(buf)
  local current = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= current and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

--- Split the window showing `buf` so `buf` ends up in an unfocused window that
--- WinLeave recorded as following.
---
--- The cursor is parked two lines above the end, in normal mode: that is what a
--- TUI's input box looks like to WinLeave (inside FOLLOW_TOLERANCE, so it counts
--- as tailing) while being *off* the last line, so nvim's own follow does not
--- engage — leaving the assertions to test this plugin's pinning and nothing
--- else. Parking exactly on the last line would tail natively, pi or not.
---@return integer follower window id, integer parked cursor line
local function leave_while_tailing(buf)
  wait_for(function()
    return vim.api.nvim_buf_line_count(buf) > 5
  end, 'terminal never produced shell output')
  vim.cmd('stopinsert')
  local parked = vim.api.nvim_buf_line_count(buf) - 2
  vim.api.nvim_win_set_cursor(0, { parked, 0 })
  vim.cmd.vsplit()
  local follower = find_follower(buf)
  assert(follower and vim.api.nvim_win_get_buf(follower) == buf, 'no unfocused window for the terminal')
  return follower, parked
end

--- Emit 30 marker lines in the terminal and wait for the buffer to grow.
local function emit_lines(buf, tag)
  local before = vim.api.nvim_buf_line_count(buf)
  vim.fn.chansend(vim.bo[buf].channel, ('for i in $(seq 1 30); do echo %s-$i; done\n'):format(tag))
  wait_for(function()
    return vim.api.nvim_buf_line_count(buf) > before + 5
  end, 'terminal never emitted marker lines')
end

-- A `:term pi` nobody registered with state.agents: followed all the same.
vim.cmd.term('pi --norc -i')
local pi_buf = vim.api.nvim_get_current_buf()
assert(state.pi.is_running(pi_buf), 'state.pi.is_running did not recognise the pi terminal')
assert(not lib.term.is_pi_agent(pi_buf), 'unregistered pi terminal counted as the pi agent')

local pi_follower = leave_while_tailing(pi_buf)
emit_lines(pi_buf, 'pi-line')
wait_for(
  function()
    return vim.api.nvim_win_get_cursor(pi_follower)[1] == vim.api.nvim_buf_line_count(pi_buf)
  end,
  ('unfocused pi window cursor (%d) not pinned to last line (%d)'):format(
    vim.api.nvim_win_get_cursor(pi_follower)[1],
    vim.api.nvim_buf_line_count(pi_buf)
  )
)
print('PASS: unregistered pi window tailed output')

-- Control: a terminal not running pi must not be tailed.
vim.cmd.enew()
vim.cmd.term('bash --norc -i')
local plain_buf = vim.api.nvim_get_current_buf()
local plain_follower, plain_parked = leave_while_tailing(plain_buf)
emit_lines(plain_buf, 'plain-line')
assert(
  vim.api.nvim_win_get_cursor(plain_follower)[1] <= plain_parked,
  'unfocused window of a terminal without pi unexpectedly tailed output'
)
print('PASS: non-pi window did not tail output')

-- pi started inside a shell terminal long after TermOpen: also followed. The
-- shell above is already left-while-tailing, so `exec pi` turns it into a pi
-- terminal without any further window switch.
vim.fn.chansend(vim.bo[plain_buf].channel, 'exec pi --norc -i\n')
wait_for(function()
  return state.pi.is_running(plain_buf)
end, 'pi started inside the shell terminal was never detected')
emit_lines(plain_buf, 'late-pi-line')
wait_for(
  function()
    return vim.api.nvim_win_get_cursor(plain_follower)[1] == vim.api.nvim_buf_line_count(plain_buf)
  end,
  ('window of a late-started pi cursor (%d) not pinned to last line (%d)'):format(
    vim.api.nvim_win_get_cursor(plain_follower)[1],
    vim.api.nvim_buf_line_count(plain_buf)
  )
)
print('PASS: pi started after TermOpen tailed output')

vim.fn.delete(fake_pi_dir, 'rf')
vim.cmd('qa!')
