vim.g.fn.rename_tab(' git log')

vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua _G.open_file_in("first_tab")<CR>', {
  desc = 'codediff: open file in first tab',
})
