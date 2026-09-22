local function is_term(buffer)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  return vim.bo[buffer].buftype == 'terminal'
end

--- Is the buffer the sticky terminal of one of the agents managed by
--- state.agents (claude, opencode, pi)?
---@param buffer integer?
---@param agent Agents
---@return boolean
local function is_agent_named(buffer, agent)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not is_term(buffer) then
    return false
  end
  local agents = state.agents
  if not agents then
    return false
  end
  return buffer == agents.get_agent_bufnr(agent)
end

--- Is the buffer the sticky terminal of any agent managed by state.agents?
---@param buffer integer?
---@return boolean
local function is_agent(buffer)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not is_term(buffer) then
    return false
  end
  local agents = state.agents
  if not agents then
    return false
  end
  for _, agent_buf in pairs(agents.bufnr) do
    if agent_buf == buffer then
      return true
    end
  end
  return false
end

--- How far above the last buffer line a terminal-window cursor can be and still
--- count as "following" output. TUIs like pi park their cursor at an input box
--- a few lines above the end, so the cursor is not exactly on the last line even
--- while tailing the stream.
local FOLLOW_TOLERANCE = 5

--- How deep into the terminal job's process tree to look for a pi process.
--- `:term pi` makes pi the job process itself (depth 0, verified: the job pid's
--- comm is `pi`); `pi` typed into a shell terminal sits one level below the
--- shell; a wrapper (`mise exec`, `npx`) adds one more.
local PI_SEARCH_DEPTH = 2

--- How long a pi-detection result is reused for a buffer (ms). Detection walks
--- /proc, and `is_pi` is called from the winbar's `%!` expression, which is
--- re-evaluated on every redraw — so the answer is cached rather than rescanned
--- per redraw. The TTL bounds how long the answer can lag pi starting/exiting.
local PI_CACHE_MS = 500
local pi_cache = {} -- bufnr -> { at = ms, value = boolean }

--- Name of process `pid`, nil when it is gone (or /proc is unavailable).
--- Reads /proc directly instead of using `nvim_get_proc`: on everything but
--- Windows that API shells out to `ps` (api/vim.c), far too slow for a caller
--- on the redraw path.
---@param pid integer
---@return string?
local function proc_name(pid)
  local ok, lines = pcall(vim.fn.readfile, '/proc/' .. pid .. '/comm', '', 1)
  if not ok then
    return nil
  end
  return lines[1]
end

--- Does `pid` — or one of its descendants, up to `depth` levels down — run pi?
--- `nvim_get_proc_children` reads /proc/<pid>/task/<pid>/children on Linux, so
--- the walk is a handful of small file reads.
---@param pid integer
---@param depth integer levels of descendants still to search
---@return boolean
local function proc_tree_runs_pi(pid, depth)
  if proc_name(pid) == 'pi' then
    return true
  end
  if depth <= 0 then
    return false
  end
  local ok, children = pcall(vim.api.nvim_get_proc_children, pid)
  if not ok then
    return false
  end
  for _, child in ipairs(children) do
    if proc_tree_runs_pi(child, depth - 1) then
      return true
    end
  end
  return false
end

--- Was the terminal's job started as pi? Terminal buffers are named
--- `term://{cwd}//{pid}:{cmd}`, so this answers for a `:term pi` from TermOpen
--- onwards — where the process tree cannot: the job process is still the shell
--- that is about to exec pi (verified: comm is `bash` at TermOpen, `pi` ~50ms
--- later), which would let the TermOpen startinsert slip through.
---@param buffer integer
---@return boolean
local function job_command_is_pi(buffer)
  local cmd = vim.api.nvim_buf_get_name(buffer):match('//%d+:(.*)$')
  local exe = cmd and cmd:match('^%s*(%S+)')
  return exe ~= nil and vim.fs.basename(exe) == 'pi'
end

--- Is a pi instance running in this terminal buffer? True for the `<leader>pi`
--- agent terminal, and equally for a pi started by hand in any other terminal
--- buffer (`:term pi`, or typed into a shell terminal).
---@param buffer integer?
---@return boolean
local function is_pi(buffer)
  if not buffer then
    buffer = vim.api.nvim_get_current_buf()
  end
  if not is_term(buffer) then
    return false
  end
  if job_command_is_pi(buffer) then
    return true
  end
  local now = vim.uv.now()
  local cached = pi_cache[buffer]
  if cached and now - cached.at < PI_CACHE_MS then
    return cached.value
  end
  local ok, pid = pcall(vim.fn.jobpid, vim.bo[buffer].channel)
  local value = ok and proc_tree_runs_pi(pid, PI_SEARCH_DEPTH) or false
  pi_cache[buffer] = { at = now, value = value }
  return value
end

---@class LibTerm
local M = {
  is_term = is_term,

  is_toggle_term = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end
    return is_term(buffer) and buffer == state.toggle_term_bufnr
  end,

  is_claude = function(buffer)
    return is_agent_named(buffer, 'claude')
  end,
  is_opencode = function(buffer)
    return is_agent_named(buffer, 'opencode')
  end,
  --- The sticky pi terminal owned by after/plugin/agents.lua — not merely a
  --- terminal that happens to run pi (that is `is_pi`).
  is_pi_agent = function(buffer)
    return is_agent_named(buffer, 'pi')
  end,
  is_pi = is_pi,
  is_agent = is_agent,

  -- Returns true if buffer is terminal, and has no running command
  -- https://github.com/neovim/neovim/issues/31313
  -- https://github.com/ilan-schemoul/nvim-config/commit/4e27ebabe9d4e819007c770800bac4d5903b8a8d
  terminal_is_available = function(buffer)
    if not buffer then
      buffer = vim.api.nvim_get_current_buf()
    end

    if not vim.api.nvim_buf_is_valid(buffer) then
      return true
    end
    if not is_term(buffer) then
      Snacks.notify.warn('Buffer is not terminal')
      return true
    end
    local channel = vim.bo[buffer].channel
    local child_process = vim.api.nvim_get_proc_children(vim.fn.jobpid(channel))
    return vim.tbl_count(child_process) == 0
  end,

  --- Was a terminal window tailing output when the user left it?
  --- While in terminal-mode the cursor is pinned to the terminal's own cursor and
  --- cannot be scrolled, so leaving from terminal-mode always counts as following.
  --- From normal-mode, follow only if the cursor is still near the end of the
  --- buffer (the user may have scrolled up to read history).
  ---@param cursor_line integer
  ---@param line_count integer
  ---@param mode string mode() result at leave time
  ---@return boolean
  was_following = function(cursor_line, line_count, mode)
    if mode == 't' then
      return true
    end
    return cursor_line >= line_count - FOLLOW_TOLERANCE
  end,

  startinsert = function()
    if not state.insert_when_entering_terminal then
      return
    end
    local win = vim.api.nvim_get_current_win()
    local is_floating = vim.api.nvim_win_get_config(win).relative ~= ''
    if is_floating then
      return
    end
    -- pi drives its own input box; nvim's insert mode fights it
    if is_pi() then
      return
    end
    vim.cmd('startinsert')
  end,
}

return M
