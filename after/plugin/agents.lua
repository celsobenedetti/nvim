state.claude_bufnr = 0
state.opencode_bufnr = 0

local function focus_buf(buf)
  local winid = vim.fn.bufwinid(buf)
  if winid ~= -1 then
    vim.api.nvim_set_current_win(winid)
  else
    vim.api.nvim_set_current_buf(buf)
  end
end

local function setup_agent(name, state_key, exclude_toggle_term)
  local function is_agent_buf(buf)
    return buf > 0
      and buf == state[state_key]
      and vim.api.nvim_buf_is_valid(buf)
      and (not exclude_toggle_term or not lib.term.is_toggle_term())
  end

  -- sticky agent terminal: focus existing buffer, or start a new one
  local function open()
    if is_agent_buf(state[state_key]) then
      focus_buf(state[state_key])
      return
    end
    vim.cmd.term(name)
    state[state_key] = vim.api.nvim_get_current_buf()
  end

  vim.api.nvim_create_autocmd('TermClose', {
    desc = name .. ': close terminal buffer when ' .. name .. ' exits',
    callback = function(args)
      if args.buf ~= state[state_key] then
        return
      end
      state[state_key] = 0
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.api.nvim_buf_delete(args.buf, { force = true })
        end
      end)
    end,
  })

  local command = name:gsub('^%l', string.upper)
  vim.api.nvim_create_user_command(command, open, { desc = 'Open or focus the ' .. name .. ' terminal' })

  local lhs = name == 'claude' and '<leader>cl' or '<leader>oC'
  vim.keymap.set('n', lhs, '<cmd>' .. command .. '<CR>', { desc = name .. ': open/focus terminal' })
end

setup_agent('claude', 'claude_bufnr', true)
setup_agent('opencode', 'opencode_bufnr', false)
