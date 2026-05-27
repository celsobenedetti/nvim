local group = vim.api.nvim_create_augroup('python_ftplugin', { clear = true })
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'python: run only once when buffer is loaded',
  group = group,
  pattern = '*.py',
  callback = function()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldlevel = 1
    vim.wo.foldnestmax = 2
  end,
})
