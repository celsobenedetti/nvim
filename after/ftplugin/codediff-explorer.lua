vim.g.fn.rename_tab(' git status')

vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':tabclose<CR>', {
  desc = 'codediff: close',
})
