local tmux_window = '!tmux neww '

vim.api.nvim_create_user_command('Clip', '!echo % | xclip -sel clip', {})

-- opens tmux popup with git diff
vim.api.nvim_create_user_command('Diff', tmux_window .. 'git diff %:p', {})

-- prompts the user for log depth, then opens tmux popup with git log -p
vim.api.nvim_create_user_command('Log', function()
  local depth = vim.fn.input('Git log depth: ', '', 'file')
  vim.cmd(tmux_window .. 'git log -p -n ' .. depth .. ' %:p')
end, {})

-- opens current file in glow
vim.api.nvim_create_user_command('Glow', tmux_window .. 'glow %:% -p', {})
-- run bash on current line

vim.api.nvim_create_user_command('Note', tmux_window .. 'note.sh', {})
