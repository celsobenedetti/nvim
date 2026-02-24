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

-- allow ":wqa" with terminal open
vim.api.nvim_create_autocmd('ExitPre', {
  pattern = '*',
  group = augroup,
  callback = function(_)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
})

vim.keymap.set('n', '<leader>te', function()
  local buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal' then
      vim.api.nvim_set_current_buf(buf)
      return
    end
  end

  -- if no terminal is open, open one
  vim.cmd('term')
end, {
  desc = 'terminal: friendly term - resume or create terminal in current window',
})
