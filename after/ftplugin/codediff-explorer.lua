local tabname = ' git status'
if vim.g.tabname then
  tabname = vim.g.tabname
  vim.g.tabname = nil
end

vim.g.fn.rename_tab(tabname)

vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':tabclose<CR>', {
  desc = 'codediff: close',
})
