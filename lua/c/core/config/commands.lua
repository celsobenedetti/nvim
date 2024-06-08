local tmux_window = '!tmux neww '

vim.api.nvim_create_user_command('Clip', '!echo % | xclip -sel clip', {})
vim.api.nvim_create_user_command('Note', tmux_window .. 'note.sh', {})

vim.api.nvim_create_user_command('Is', function(args)
  require('c.functions.jira').open_issue(args.args)
end, { nargs = 1 })
