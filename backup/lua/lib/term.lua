local M = {}

local function get_first_terminal()
  local terminal_chans = {}

  for _, chan in pairs(vim.api.nvim_list_chans()) do
    if chan['mode'] == 'terminal' and chan['pty'] ~= '' then
      table.insert(terminal_chans, chan)
    end
  end

  table.sort(terminal_chans, function(left, right)
    return left['buffer'] < right['buffer']
  end)

  return terminal_chans[1]['id']
end

function M.terminal_send(text)
  local first_terminal_chan = get_first_terminal()

  vim.schedule(function()
    vim.api.nvim_chan_send(first_terminal_chan, text .. '\n')
  end)
end

--- run command on current file
---@param cmd string
function M.run_on_buffer(cmd)
  local file = vim.fn.expand '%:p'
  local current_term = Snacks.terminal.get()
  if not current_term or current_term.closed then
    Snacks.terminal.toggle()
  end

  vim.schedule(function()
    M.terminal_send(cmd .. file)
  end)
end

return M
