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
  is_pi = function(buffer)
    return is_agent_named(buffer, 'pi')
  end,
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
    vim.cmd('startinsert')
  end,
}

return M
