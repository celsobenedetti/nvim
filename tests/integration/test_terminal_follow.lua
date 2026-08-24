-- Integration test (real nvim, headless): the pi-terminal follow feature in
-- after/plugin/terminal.lua tails output in unfocused windows showing the pi
-- buffer, while plain unregistered terminals are left alone.
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

-- Two splits showing the pi terminal; stay focused in the second one so the
-- first window is unfocused when output arrives.
vim.cmd.term('bash')
local pi_buf = vim.api.nvim_get_current_buf()
-- Replicate agents.lua open() ordering: register after :term returns.
state.agents.set_agent_bufnr('pi', pi_buf)

wait_for(function()
  return vim.api.nvim_buf_line_count(pi_buf) > 3
end, 'pi terminal never produced shell output')
-- Simulate a user keeping up with output: park the cursor on the last line
-- before leaving, otherwise WinLeave rightly records the window as not following.
vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(pi_buf), 0 })
vim.cmd.vsplit()
local follower_win = find_follower(pi_buf)
assert(follower_win and vim.api.nvim_win_get_buf(follower_win) == pi_buf, 'no unfocused pi window')

vim.fn.chansend(vim.bo[pi_buf].channel, 'for i in $(seq 1 30); do echo pi-line-$i; done\n')
wait_for(function()
  return vim.api.nvim_buf_line_count(pi_buf) > 35
end, 'pi terminal never emitted marker lines')
wait_for(
  function()
    return vim.api.nvim_win_get_cursor(follower_win)[1] == vim.api.nvim_buf_line_count(pi_buf)
  end,
  ('unfocused pi window cursor (%d) not pinned to last line (%d)'):format(
    vim.api.nvim_win_get_cursor(follower_win)[1],
    vim.api.nvim_buf_line_count(pi_buf)
  )
)
print('PASS: pi window tailed output')

-- Control: a plain terminal nobody registered must not be tailed.
vim.cmd.enew()
vim.cmd.term('bash')
local plain_buf = vim.api.nvim_get_current_buf()

wait_for(function()
  return vim.api.nvim_buf_line_count(plain_buf) > 3
end, 'plain terminal never produced shell output')
-- Leave the cursor mid-buffer: parked exactly on the last line, nvim's built-in
-- terminal tailing would engage for any terminal, registered or not.
vim.cmd.vsplit()
local plain_follower_win = find_follower(plain_buf)
assert(plain_follower_win and vim.api.nvim_win_get_buf(plain_follower_win) == plain_buf, 'no unfocused plain window')

local plain_start = vim.api.nvim_win_get_cursor(plain_follower_win)[1]
vim.fn.chansend(vim.bo[plain_buf].channel, 'for i in $(seq 1 30); do echo plain-line-$i; done\n')
wait_for(function()
  return vim.api.nvim_buf_line_count(plain_buf) > 35
end, 'plain terminal never emitted marker lines')
assert(
  vim.api.nvim_win_get_cursor(plain_follower_win)[1] <= plain_start,
  'unfocused plain window unexpectedly tailed output'
)
print('PASS: plain window did not tail output')

vim.cmd('qa!')
