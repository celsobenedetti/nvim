vim.api.nvim_buf_set_keymap(
  0,
  'n',
  '<leader>ok',
  ':lua vim.cmd("normal! ggdd");vim.cmd("wq")<CR>',
  { desc = 'gitcommit: cancel commit' }
)

-- Insert mode when entering git commit
vim.api.nvim_feedkeys(Keys('i<BS>'), 'n', true)
