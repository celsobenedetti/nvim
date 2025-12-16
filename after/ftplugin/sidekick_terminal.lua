-- normalize windows after toggling sidekick
vim.schedule(function()
  vim.cmd('wincmd =')
end)
