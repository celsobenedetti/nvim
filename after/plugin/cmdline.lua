vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('celso_cmdline', { clear = true }),
  desc = 'clear cmdline',
  callback = lib.cmdline.clear,
})

vim.keymap.set('c', '<Tab>', lib.cmdline.fzf_tab, {
  desc = 'cmd: fzf files/dirs when line ends with **',
})

vim.keymap.set('c', '<C-v>', function()
  lib.cmdline.open_split('vsplit')
end, { desc = 'cmd: :e file in a vertical split' })

vim.keymap.set('c', '<C-s>', function()
  lib.cmdline.open_split('split')
end, { desc = 'cmd: :e file in a horizontal split' })

for _, cmd in ipairs({ '*', '#', 'g*', 'g#' }) do
  vim.keymap.set('n', cmd, function()
    lib.cmdline.clear()
    vim.fn.feedkeys(vim.v.count1 .. cmd, 'n')
  end)
end
