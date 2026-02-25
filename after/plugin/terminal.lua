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

vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = 'term://*',
  group = augroup,
  callback = function()
    -- Insert mode when entering terminal window
    vim.api.nvim_feedkeys(Keys('i<BS>'), 'n', true)
  end,
})

-- -- allow ":wqa" with terminal open
-- vim.api.nvim_create_autocmd('ExitPre', {
--   pattern = '*',
--   group = augroup,
--   callback = function(_)
--     for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--       if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
--         vim.api.nvim_buf_delete(buf, { force = true })
--       end
--     end
--   end,
-- })

-- FIX: should get the terminal buffer with the smallest name
-- the idea is to get a terminal with no commands running
-- if there is command running, should probably open a new terminal
--
-- vim.keymap.set('n', '<leader>te', function()
--   local buffers = vim.api.nvim_list_bufs()
--   for _, buf in ipairs(buffers) do
--     if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
--       vim.api.nvim_set_current_buf(buf)
--       return
--     end
--   end
--
--   -- if no terminal is open, open one
--   vim.cmd('term')
-- end, {
--   desc = 'terminal: friendly term - resume or create terminal in current window',
-- })

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

-- tmux <C-/> mapping
vim.keymap.set('n', vim.g.tmux.mappings['<C-/>'], function()
  return toggle_terminal()
end, { desc = 'Toggle terminal' })
vim.keymap.set('t', vim.g.tmux.mappings['<C-/>'], '<C-\\><C-n><C-w>c', { desc = 'Close terminal' })
