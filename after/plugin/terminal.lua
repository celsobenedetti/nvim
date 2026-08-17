vim.g.insert_when_entering_terminal = true

local lib = require('lib')

--- @module 'sticky terminal'
--- upsert terminal in current window (resume if available, create new otherwise)
local function sticky_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if lib.term.is_term(buf) and not lib.term.is_toggle_term(buf) and lib.term.terminal_is_available(buf) then
      vim.api.nvim_set_current_buf(buf)
      return
    end
  end
  vim.cmd.term()
end
vim.keymap.set('n', '<leader>te', sticky_terminal, { desc = 'terminal: sticky terminal' })

--- @module 'toggle terminal'
--- references:
---     https://github.com/kristijanhusak/neovim-config/commit/5f8da622f6668ba3744b33facfa88bd48a6e56a4#diff-4a7625707401ac0489aab5c8a5daca2adb4ef8de341c8d523d93e6c507fc58d4
vim.g.toggle_term_bufnr = -1
local function toggle_terminal()
  local target_height = math.max(20, math.floor(vim.fn.winheight(0) * 0.5))
  if vim.g.toggle_term_bufnr < 0 then
    vim.cmd('botright sp | term')
    vim.cmd.resize(target_height)
    vim.cmd.setlocal('bufhidden=hide')
    vim.g.toggle_term_bufnr = vim.api.nvim_get_current_buf()
    return
  end

  local winnr = vim.fn.bufwinnr(vim.g.toggle_term_bufnr)
  if winnr > -1 then
    vim.api.nvim_win_close(vim.fn.win_getid(winnr), true)
    return
  end
  if not vim.api.nvim_buf_is_valid(vim.g.toggle_term_bufnr) then
    vim.g.toggle_term_bufnr = -1
    return
  end
  vim.cmd('botright sp | b' .. vim.g.toggle_term_bufnr)
  vim.cmd.resize(target_height)
end
vim.keymap.set('n', vim.g.keys['<C-/>'], toggle_terminal, { desc = 'Toggle terminal' })

vim.keymap.set('t', vim.g.keys['<C-/>'], function()
  if vim.api.nvim_get_current_buf() == vim.g.toggle_term_bufnr then
    vim.api.nvim_input('<C-\\><C-n><C-w>c')
  end
end, { desc = 'Close toggle terminal' })

--- @module 'terminal autocmds'
-- stylua: ignore start
local augroup = vim.api.nvim_create_augroup('custom-term', {})
-- insert mode when entering terminal window
vim.api.nvim_create_autocmd('BufWinEnter', { desc = 'terminal: insert mode when entering terminal window', pattern = 'term://*', group = augroup, callback = lib.term.startinsert, })
vim.api.nvim_create_autocmd('WinEnter', { desc = 'terminal: insert mode when entering terminal window', pattern = 'term://*', group = augroup, callback = lib.term.startinsert, })
-- stylua: ignore end

vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'term: TermOpen init function',
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.scrolloff = 0
    vim.bo.filetype = 'terminal'
    vim.schedule(lib.term.startinsert)
  end,
})

vim.api.nvim_create_autocmd('TermClose', {
  desc = 'term: TermClose cleanup',
  callback = function()
    local bufs = lib.buffers.get_valid_bufs()
    for _, buf in ipairs(bufs) do
      if buf == vim.g.toggle_term_bufnr then -- float term still open
        return
      end
    end
    vim.g.toggle_term_bufnr = -1
  end,
  group = augroup,
})

vim.api.nvim_create_autocmd('ExitPre', {
  desc = 'term: cleanup idle terminal when exiting neovim',
  callback = function()
    local term_bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
        table.insert(term_bufs, buf)
      end
    end
    if #term_bufs == 0 then
      return
    end

    local busy_terms = {}
    for _, buf in ipairs(term_bufs) do
      if lib.terminal_is_available(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        table.insert(busy_terms, buf)
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
