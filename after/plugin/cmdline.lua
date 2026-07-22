-- clear cmdline after 5s
local function clear_cmdline()
  vim.fn.timer_start(5000, function()
    print(' ')
  end)
end

vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('celso_cmdline', { clear = true }),
  desc = 'clear cmdline',
  callback = clear_cmdline,
})

for _, cmd in ipairs({ '*', '#', 'g*', 'g#' }) do
  vim.keymap.set('n', cmd, function()
    clear_cmdline()
    vim.fn.feedkeys(vim.v.count1 .. cmd, 'n')
  end)
end
