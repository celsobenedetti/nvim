vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('celso_cmdline', { clear = true }),
  desc = 'clear cmdline',
  callback = lib.cmdline.clear,
})

vim.keymap.set('c', '<Tab>', lib.cmdline.fzf_tab, {
  desc = 'cmd: fzf files/dirs when line ends with **',
})

for _, cmd in ipairs({ '*', '#', 'g*', 'g#' }) do
  vim.keymap.set('n', cmd, function()
    lib.cmdline.clear()
    vim.fn.feedkeys(vim.v.count1 .. cmd, 'n')
  end)
end
