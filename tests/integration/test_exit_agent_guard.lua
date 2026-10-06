-- Integration test (real nvim, headless): the ExitPre guard in
-- after/plugin/terminal.lua asks before letting nvim exit while an agent CLI
-- (config.agents) is alive in one of its terminals, and honours the answer.
--
-- ExitPre cannot refuse an exit by returning, so the guard aborts by replacing
-- the window the quit started from with a split (abort_quit there). Whether
-- `:qa` actually comes back is the whole point, so each case runs in a child
-- nvim that writes a marker file only if its `:qa` was refused -- asserting
-- after a `:qa` in-process proves nothing, since an exit that wrongly went
-- through just ends the test with a success status.
--
-- The agent is stood in for by a copy of bash named `pi`: what the guard keys
-- off is the process name under the terminal's job, and a shell copy gives us a
-- pi-named process that stays alive.
--
-- vim.fn.confirm() is stubbed; with no UI it would read the answer off stdin.
--
-- Run via `make test-integration` (nvim --headless -u NONE -l).

local script = debug.getinfo(1, 'S').source:sub(2)
local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = cwd .. '/lua/?.lua;' .. package.path

local function assert_eq(got, want, msg)
  if vim.inspect(got) ~= vim.inspect(want) then
    error(string.format('%s: got %s, want %s', msg or 'assert', vim.inspect(got), vim.inspect(want)))
  end
end

local function assert_true(cond, msg)
  if not cond then
    error(msg or 'assert_true failed')
  end
end

-- ================================================================
-- Child: set up a terminal, try to quit, record a refusal.
-- ================================================================
if vim.env.EXIT_GUARD_CHILD then
  -- Globals after/plugin/terminal.lua expects from the live config.
  _G.state = {}
  _G.config = {
    keys = { ['<C-/>'] = '<C-_>' },
    agents = {
      { key = '<leader>cl', cmd = 'claude' },
      { key = '<leader>op', cmd = 'opencode' },
      { key = '<leader>pi', cmd = 'pi' },
    },
  }
  _G.lib = {
    term = require('lib.term'),
    buffers = {
      get_valid_bufs = function()
        return {}
      end,
    },
  }
  _G.Snacks = { notify = { warn = function() end } }

  vim.cmd('luafile ' .. cwd .. '/after/plugin/terminal.lua')

  local prompts = {}
  vim.fn.confirm = function(msg)
    prompts[#prompts + 1] = msg
    return tonumber(vim.env.EXIT_GUARD_ANSWER)
  end
  -- The guard only prompts an interactive session; pose as one.
  vim.api.nvim_list_uis = function()
    return { {} }
  end

  vim.cmd.edit(vim.fn.tempname() .. '.txt')
  vim.cmd('botright sp | term ' .. vim.env.EXIT_GUARD_CMD)
  local term_buf = vim.api.nvim_get_current_buf()
  vim.wait(2000, function()
    return lib.term.job_runs_process(term_buf, vim.env.EXIT_GUARD_PROC, 2)
  end)
  if not lib.term.job_runs_process(term_buf, vim.env.EXIT_GUARD_PROC, 2) then
    io.stderr:write('child: terminal never ran ' .. vim.env.EXIT_GUARD_PROC .. '\n')
    os.exit(2)
  end

  -- Quit from the file window, as the user would. (From the terminal window the
  -- idle-terminal cleanup can close the quitting window out from under nvim and
  -- abort the exit on its own, which would mask the guard.)
  vim.cmd.wincmd('p')
  pcall(vim.cmd, 'qa')

  -- Still here: the exit was refused.
  vim.fn.writefile({ 'refused', prompts[1] or '<no prompt>' }, vim.env.EXIT_GUARD_MARKER)
  -- Leave through Lua: `:qa!` would re-enter the guard.
  os.exit(0)
end

-- ================================================================
-- Parent
-- ================================================================

-- A process really named `pi`, so /proc/<pid>/comm matches an entry of
-- config.agents. `:term` execs a simple command, so it is the job process.
local bin = vim.fn.tempname()
vim.fn.mkdir(bin, 'p')
local agent = bin .. '/pi'
vim.fn.system({ 'cp', vim.fn.exepath('bash'), agent })
assert_eq(vim.v.shell_error, 0, 'fake agent copied')

---Run the child and return the marker lines it left, or nil when it exited.
---@param answer string what the stubbed confirm() returns
---@param cmd string command for the child's `:term`
---@param proc string process name the child waits for
---@return string[]?
local function quit_with(answer, cmd, proc)
  local marker = vim.fn.tempname()
  local child = vim
    .system({ 'nvim', '--headless', '-u', 'NONE', '-l', script }, {
      text = true,
      timeout = 20000,
      env = {
        EXIT_GUARD_CHILD = '1',
        EXIT_GUARD_ANSWER = answer,
        EXIT_GUARD_CMD = cmd,
        EXIT_GUARD_PROC = proc,
        EXIT_GUARD_MARKER = marker,
      },
    })
    :wait()
  assert_eq(child.code, 0, 'child exited cleanly (stderr: ' .. (child.stderr or '') .. ')')
  if vim.fn.filereadable(marker) == 0 then
    return nil
  end
  return vim.fn.readfile(marker)
end

-- "No" keeps nvim alive, and the prompt names the agent that is running.
local refused = quit_with('2', agent, 'pi')
assert_true(refused ~= nil, 'exit refused while the agent runs')
assert_true(refused[2]:match('^pi still running'), 'prompt names the running agent: ' .. refused[2])

-- Esc/interrupt answers 0, which is not a Yes either.
assert_true(quit_with('0', agent, 'pi') ~= nil, 'an interrupted prompt refuses the exit')

-- "Yes" lets the exit through.
assert_eq(quit_with('1', agent, 'pi'), nil, 'exit allowed after confirming')

-- A terminal running something else is not an agent: no prompt, no guard. The
-- answer would refuse if it were ever asked for.
assert_eq(quit_with('2', 'sleep 30', 'sleep'), nil, 'a non-agent terminal does not guard the exit')
