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

    vim.cmd(string.format("!tmux send-keys -t '{right-of}' '%s '", text))
    vim.cmd('!tmux select-pane -t 1')
  end)
end

return M
