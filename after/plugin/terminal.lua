vim.g.insert_when_entering_terminal = true
local float_term_bufnr = 0

local lib = {
  -- Returns true if buffer is terminal, and has no running command
  -- https://github.com/neovim/neovim/issues/31313
  -- https://github.com/ilan-schemoul/nvim-config/commit/4e27ebabe9d4e819007c770800bac4d5903b8a8d
  terminal_is_available = function(buffer)
    local is_terminal = vim.bo[buffer].buftype == 'terminal'
    if not is_terminal then
      Snacks.notify.error('terminal_is_available called on non terminal buffer')
      return true
    end
    local channel = vim.bo[buffer].channel
    local child_process = vim.api.nvim_get_proc_children(vim.fn.jobpid(channel))
    return vim.tbl_count(child_process) == 0
  end,

  startinsert = function()
    if
      not vim.g.insert_when_entering_terminal
      or not vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative == '' -- is not valid window
    then
      return
    end
    vim.cmd('startinsert')
  end,
}

-- friendly term - upsert terminal in current window (resume if available, create new otherwise)
vim.keymap.set('n', '<leader>te', function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' and lib.terminal_is_available(buf) then
      vim.api.nvim_set_current_buf(buf)
      lib.startinsert()
      return
    end
  end
  -- no terminal available, create a new one
  vim.cmd.term()
end, {
  desc = 'terminal: friendly term - upsert terminal in current window (resume if available, create new otherwise)',
})

-- taken from: https://github.com/kristijanhusak/neovim-config/commit/5f8da622f6668ba3744b33facfa88bd48a6e56a4#diff-4a7625707401ac0489aab5c8a5daca2adb4ef8de341c8d523d93e6c507fc58d4
local function toggle_terminal()
  if float_term_bufnr <= 0 then
    vim.cmd([[sp | term]])
    vim.cmd([[setlocal bufhidden=hide]])
    float_term_bufnr = vim.api.nvim_get_current_buf()
    return
  end

  local win = vim.fn.bufwinnr(float_term_bufnr)
  if win > -1 then
    vim.cmd(win .. 'close')
    return
  end
  vim.cmd('sp | b' .. float_term_bufnr)
end

vim.keymap.set('n', vim.g.mappings.tmux['<C-/>'], toggle_terminal, { desc = 'Toggle terminal' })
vim.keymap.set('t', vim.g.mappings.tmux['<C-/>'], '<C-\\><C-n><C-w>c', { desc = 'Close terminal' })

-- Autocmds
local augroup = vim.api.nvim_create_augroup('custom-term', {})
vim.api.nvim_create_autocmd('TermOpen', {
  group = augroup,
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.scrolloff = 0
    vim.bo.filetype = 'terminal'
    vim.schedule(lib.startinsert)
  end,
})

vim.api.nvim_create_autocmd('TabNew', {
  desc = '"detach" toggle term when opening new tab',
  pattern = '*',
  callback = function()
    if vim.api.nvim_get_current_buf() == float_term_bufnr then
      Snacks.notify.info('Detached', { title = 'Toggle term', icon = '', style = 'fancy' })
      float_term_bufnr = 0
    end
  end,
})

vim.api.nvim_create_autocmd('BufDelete', {
  pattern = 'term://*',
  callback = function()
    if vim.api.nvim_get_current_buf() == float_term_bufnr then
      float_term_bufnr = 0
    end
  end,
})

vim.api.nvim_create_autocmd('ExitPre', {
  callback = function()
    local busy_terms = {}
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
      if 'terminal' == vim.api.nvim_buf_get_option(buf, 'buftype') then
        if lib.terminal_is_available(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        else
          table.insert(busy_terms, buf)
        end
      end
    end

    if #busy_terms > 0 then
      local msg = string.format(
        'there %s %d busy terminal%s',
        #busy_terms > 1 and 'are' or 'is',
        #busy_terms,
        #busy_terms > 1 and 's' or ''
      )
      Snacks.notify.warn(msg, { title = 'Running commands', icon = '', style = 'fancy' })
      vim.cmd.buffer(busy_terms[1])
    end
  end,
})



-- stylua: ignore start
-- insert mode when entering terminal window
vim.api.nvim_create_autocmd('BufWinEnter', { desc = 'terminal: insert mode when entering terminal window', pattern = 'term://*', group = augroup, callback = lib.startinsert, })
vim.api.nvim_create_autocmd( 'WinEnter', { desc = 'terminal: insert mode when entering terminal window', pattern = 'term://*', group = augroup, callback = lib.startinsert, })
