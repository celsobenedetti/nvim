vim.defer_fn(function()
  vim.cmd 'Org agenda T'
end, 10)

vim.defer_fn(function()
  vim.cmd 'Neotree show'
end, 200)
