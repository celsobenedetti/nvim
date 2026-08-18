---@class LibTmux
local M = {}

M.active = function()
  local tmux = os.getenv('TMUX')
  if not tmux or tmux == '' then
    return false
  end
  return true
end

--- launches new window with command
---@param cmd string
---@param opts? table
M.neww = function(cmd, opts)
  opts = opts or {}
  if opts.name then
    cmd = string.format('-n "%s" %s', opts.name, cmd)
  end

  vim.cmd('silent! !tmux neww  ' .. cmd .. '')
end

M.send_text = function(text)
  vim.schedule(function()
    if not M.active() then
      return
    end

    vim.cmd(string.format("silent! !tmux send-keys -t '{right-of}' '%s '", text))
    vim.cmd('silent! !tmux select-pane -t 1')
  end)
end

--- workmux primitives -------------------------------------------------------

--- Resolve the canonical git toplevel of a path (realpath of
--- `rev-parse --show-toplevel`). Cached per path to avoid repeated subprocess
--- spawns when enumerating agents. `path` may be a file or directory.
---@param path string
---@return string?
local cache = {}
M.git_toplevel = function(path)
  if cache[path] then
    return cache[path]
  end
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ':h')
  local out = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then
    cache[path] = false
    return nil
  end
  local resolved = vim.trim(out):gsub('%s+$', '')
  cache[path] = resolved
  return resolved
end

--- Parse `workmux status --json` into a list of all live agents, regardless
--- of repository. Each agent carries its worktree path (workdir), used to
--- decide relative-vs-absolute path resolution.
---@return {handle:string, branch:string, status:string, title:string, workdir:string, agent_kind:string}[]
M.workmux_agents = function()
  if not M.active() then
    return {}
  end

  local output = vim.fn.system({ 'workmux', 'status', '--json' })
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok or not data or not data.agents then
    return {}
  end

  local agents = {}
  for _, agent in ipairs(data.agents) do
    table.insert(agents, {
      handle = agent.worktree,
      branch = agent.branch,
      status = agent.status,
      title = agent.title,
      workdir = agent.workdir,
      agent_kind = agent.agent_kind,
    })
  end
  return agents
end

--- Send text to a running workmux agent by its worktree handle.
---@param handle string
---@param text string
---@return boolean ok
M.workmux_send = function(handle, text)
  if not M.active() then
    return false
  end
  vim.fn.system({ 'workmux', 'send', handle, text })
  return vim.v.shell_error == 0
end

return M
