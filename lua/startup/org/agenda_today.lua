local fullscreen = false

-- vim.defer_fn(function()
vim.cmd 'Org agenda T'
-- end, 10)

if fullscreen then
  vim.defer_fn(function()
    vim.cmd 'wincmd k'
    vim.api.nvim_win_close(0, false)
  end, 50)
end
