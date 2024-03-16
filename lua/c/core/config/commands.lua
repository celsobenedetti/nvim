local tmux_window = '!tmux neww '

vim.api.nvim_create_user_command('Clip', '!echo % | xclip -sel clip', {})
vim.api.nvim_create_user_command('Note', tmux_window .. 'note.sh', {})
