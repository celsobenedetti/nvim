vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua _G.open_file_in("top_split")<CR>', {
  desc = 'terminal: open file in top split',
})
