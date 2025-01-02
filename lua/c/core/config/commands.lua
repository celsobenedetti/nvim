local tmux_window = '!tmux neww '

vim.api.nvim_create_user_command('Clip', '!echo % | xclip -sel clip', {})
vim.api.nvim_create_user_command('Note', tmux_window .. 'note.sh', {})

vim.api.nvim_create_user_command('Is', function(args)
  require('c.functions.issues').open_issue(args.args)
end, { nargs = 1 })

-- stylua: ignore
local write_buffer = function() vim.cmd 'wa' end
vim.api.nvim_create_user_command('Wa', write_buffer, { nargs = 0 })
vim.api.nvim_create_user_command('WA', write_buffer, { nargs = 0 })
