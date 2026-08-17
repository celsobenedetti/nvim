vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua lib.fs.open_file_in("first_tab")<CR>', {
  desc = 'codediff: open file in first tab',
})
