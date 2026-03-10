vim.api.nvim_buf_set_keymap(
  0,
  'n',
  '<leader>ok',
  ':lua vim.cmd("normal! ggdd");vim.cmd("wq")<CR>',
  { desc = 'gitcommit: cancel commit' }
)

vim.cmd('startinsert')
