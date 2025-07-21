vim.defer_fn(function()
  vim.cmd 'Org agenda T'
end, 10)

vim.defer_fn(function()
  vim.cmd 'Neotree position=left'
end, 200)
