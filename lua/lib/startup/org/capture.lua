local delay = {
  org_capture = 10,
  delete_top_buffer = 50,
}

vim.defer_fn(function()
  vim.cmd 'Org agenda T'
end, delay.agenda_startup)

vim.defer_fn(function()
  vim.cmd 'wincmd k'
  vim.api.nvim_win_close(0, false)
end, delay.delete_top_buffer)
