--- Custom commands

local new_tmux_window = '!tmux neww '

vim.api.nvim_create_user_command('Clip', '!echo % | xclip -sel clip', { desc = 'Yank current file path to clipboard' })
vim.api.nvim_create_user_command('Note', new_tmux_window .. 'note.sh', { desc = 'Create new note in new tmux window' })

vim.api.nvim_create_user_command('Is', function(args)
  require('c.functions.issues').open_issue(args.args)
end, { nargs = 1 })

-- Monkeytype
vim.api.nvim_create_user_command('Mt', function()
  vim.ui.open 'https://monkeytype.com'
end, { nargs = 0 })


-- Convenient support for typos when saving file
-- stylua: ignore
local write_buffer = function() vim.cmd 'wa' end
vim.api.nvim_create_user_command('Wa', write_buffer, { nargs = 0 })
vim.api.nvim_create_user_command('WA', write_buffer, { nargs = 0 })
