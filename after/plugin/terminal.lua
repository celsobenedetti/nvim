local augroup = vim.api.nvim_create_augroup('custom-term', {})
-- Set local settings for terminal buffers
vim.api.nvim_create_autocmd('TermOpen', {
  group = augroup,
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.scrolloff = 0
    vim.bo.filetype = 'terminal'

    -- Insert mode when entering terminal
    vim.api.nvim_feedkeys(Keys('i<BS>'), 'n', true)
  end,
})

-- BUG: there is something of with this implementation, where I get error messages some times.
-- besides this, there are some times where I don't want to insert
vim.g.insert_when_entering_terminal = true
vim.api.nvim_create_autocmd('WinEnter', {
  desc = 'terminal: insert mode when entering terminal window',
  pattern = 'term://*',
  group = augroup,
  callback = function()
    local is_valid_win = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative == '' -- is not valid window
    if not vim.g.insert_when_entering_terminal or not is_valid_win then
      return
    end

    vim.cmd('startinsert')
  end,
})

-- Returns true if buffer is terminal, and has no running command
-- https://github.com/neovim/neovim/issues/31313
-- https://github.com/ilan-schemoul/nvim-config/commit/4e27ebabe9d4e819007c770800bac4d5903b8a8d
local function terminal_is_available(buffer)
  local is_terminal = vim.bo[buffer].buftype == 'terminal'
  if not is_terminal then
    return false
  end
  local channel = vim.bo[buffer].channel
  local child_process = vim.api.nvim_get_proc_children(vim.fn.jobpid(channel))
  return vim.tbl_count(child_process) == 0
end

vim.keymap.set('n', '<leader>te', function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' and terminal_is_available(buf) then
      vim.api.nvim_set_current_buf(buf)
      vim.cmd('norm i')
      return
    end
  end
  -- no terminal available, create a new one
  vim.cmd.term()
end, {
  desc = 'terminal: friendly term - resume or create terminal in current window',
})

-- taken from: https://github.com/kristijanhusak/neovim-config/commit/5f8da622f6668ba3744b33facfa88bd48a6e56a4#diff-4a7625707401ac0489aab5c8a5daca2adb4ef8de341c8d523d93e6c507fc58d4
local terminal_bufnr = 0
local function toggle_terminal(close)
  if close then
    terminal_bufnr = 0
    return
  end
  if terminal_bufnr <= 0 then
    vim.api.nvim_create_autocmd('TermOpen', {
      pattern = '*',
      command = 'startinsert',
      once = true,
    })
    vim.cmd([[sp | term]])
    vim.cmd([[setlocal bufhidden=hide]])
    vim.api.nvim_create_autocmd('BufDelete', {
      pattern = '<buffer>',
      callback = function()
        toggle_terminal(true)
      end,
    })
    terminal_bufnr = vim.api.nvim_get_current_buf()
    return
  end

  local win = vim.fn.bufwinnr(terminal_bufnr)

  if win > -1 then
    vim.cmd(win .. 'close')
    return
  end

  vim.cmd('sp | b' .. terminal_bufnr .. ' | startinsert')
end
vim.api.nvim_create_autocmd('TabNew', {
  desc = '"detach" toggle term when opening new tab',
  pattern = '*',
  callback = function()
    if vim.api.nvim_get_current_buf() == terminal_bufnr then
      terminal_bufnr = 0
    end
  end,
})

vim.keymap.set('n', vim.g.mappings.tmux['<C-/>'], function()
  return toggle_terminal()
end, { desc = 'Toggle terminal' })
vim.keymap.set('t', vim.g.mappings.tmux['<C-/>'], '<C-\\><C-n><C-w>c', { desc = 'Close terminal' })
