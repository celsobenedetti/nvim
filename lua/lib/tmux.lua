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

--- Focus the tmux window and pane containing a given pane_id.
--- Uses `switch-client` (like workmux) so the user's attached client is moved
--- to the target pane even across sessions.
---@param pane_id string
---@return boolean ok
M.focus_pane = function(pane_id)
  if not M.active() or not pane_id or pane_id == '' then
    return false
  end
  vim.fn.system({ 'tmux', 'switch-client', '-t', pane_id })
  return vim.v.shell_error == 0
end

--- Send text to a tmux pane without pressing Enter.
--- Multiline text goes through `load-buffer` + `paste-buffer`, which preserves
--- line breaks exactly; single-line text uses `send-keys -l` so special chars
--- are typed as-is.
---@param pane_id string
---@param text string
---@return boolean ok
M.send_to_pane = function(pane_id, text)
  if not M.active() or not pane_id or pane_id == '' then
    return false
  end
  if text:find('\n') then
    local tmp = vim.fn.tempname()
    local f = io.open(tmp, 'w')
    if not f then
      return false
    end
    f:write(text)
    f:close()
    vim.fn.system({ 'tmux', 'load-buffer', tmp })
    os.remove(tmp)
    if vim.v.shell_error ~= 0 then
      return false
    end
    vim.fn.system({ 'tmux', 'paste-buffer', '-t', pane_id, '-p', '-d' })
  else
    vim.fn.system({ 'tmux', 'send-keys', '-t', pane_id, '-l', text })
  end
  return vim.v.shell_error == 0
end

return M
