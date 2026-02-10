vim.api.nvim_buf_set_keymap(0, 'n', 'gf', ':lua _G.open_file_in("top_split")<CR>', {
  desc = 'compilation: open file in top split',
})

vim.schedule(function()
  -- focus compilation window when it loads
  vim.cmd('wincmd j')
end)
