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

--- Pid of the terminal buffer's job, nil when it has no live channel.
---@param buffer integer
---@return integer?
local function job_pid(buffer)
  local ok, pid = pcall(vim.fn.jobpid, vim.bo[buffer].channel)
  return ok and pid or nil
end

--- Command the terminal's job was started with, nil for a non-terminal buffer.
--- Terminal buffers are named `term://{cwd}//{pid}:{cmd}`, so this answers from
--- TermOpen onwards — before the job process has exec'd the command, which the
--- process tree cannot (see job_runs_process).
---@param buffer integer
---@return string?
local function job_command(buffer)
  return vim.api.nvim_buf_get_name(buffer):match('//%d+:(.*)$')
end

--- Name of process `pid`, nil when it is gone (or /proc is unavailable).
--- Reads /proc directly instead of using `nvim_get_proc`: on everything but
--- Windows that API shells out to `ps` (api/vim.c), far too slow for callers on
--- a redraw path.
---@param pid integer
---@return string?
local function proc_name(pid)
  local ok, lines = pcall(vim.fn.readfile, '/proc/' .. pid .. '/comm', '', 1)
  if not ok then
    return nil
  end
  return lines[1]
end

--- Is `pid`, or one of its descendants up to `depth` levels down, named `name`?
--- `nvim_get_proc_children` reads /proc/<pid>/task/<pid>/children on Linux, so
--- the walk is a handful of small file reads.
---@param pid integer
---@param name string
---@param depth integer levels of descendants still to search
---@return boolean
local function proc_tree_has(pid, name, depth)
  if proc_name(pid) == name then
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
    if proc_tree_has(child, name, depth - 1) then
      return true
    end
  end
  return false
end

--- Does the terminal buffer's job run a process called `name` — either as the
--- job process itself, or as a descendant up to `depth` levels down? Catches a
--- program started by hand in a shell terminal, where the job process is the
--- shell and the program one of its children.
---
--- Note this lags a `:term <name>` by a few ms: the job process is the shell
--- about to exec the command, so at TermOpen the tree still says `bash`
--- (measured: `pi` only ~50ms later). Pair it with `job_command` when the
--- answer is needed at TermOpen time.
---@param buffer integer
---@param name string process name as /proc/<pid>/comm reports it (no path)
---@param depth integer? levels of descendants to search, default 1
---@return boolean
local function job_runs_process(buffer, name, depth)
  if not is_term(buffer) then
    return false
  end
  local pid = job_pid(buffer)
  return pid ~= nil and proc_tree_has(pid, name, depth or 1)
end

--- Terminals that should be left in normal mode on entry, as predicates over
--- the entered buffer. Plugin files append their own rather than `startinsert`
--- knowing about them (after/plugin/pi.lua: a pi TUI drives its own input box,
--- so nvim's insert mode only fights it).
---@type (fun(buffer: integer): boolean)[]
local startinsert_exemptions = {}

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
  --- terminal that happens to run pi (that is `state.pi.is_running`, from
  --- after/plugin/pi.lua).
  is_pi_agent = function(buffer)
    return is_agent_named(buffer, 'pi')
  end,
  is_agent = is_agent,

  job_pid = job_pid,
  job_command = job_command,
  job_runs_process = job_runs_process,

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

  startinsert_exemptions = startinsert_exemptions,

  startinsert = function()
    if not state.insert_when_entering_terminal then
      return
    end
    local win = vim.api.nvim_get_current_win()
    local is_floating = vim.api.nvim_win_get_config(win).relative ~= ''
    if is_floating then
      return
    end
    local buffer = vim.api.nvim_get_current_buf()
    for _, exempt in ipairs(startinsert_exemptions) do
      if exempt(buffer) then
        return
      end
    end
    vim.cmd('startinsert')
  end,
}

return M
