local command = vim.api.nvim_create_user_command
local new_tmux_window = "!tmux neww "

command("Clip", "!printf % | xclip -sel clip", { desc = "Yank current file path to clipboard" })
command("Note", new_tmux_window .. "note.sh", { desc = "Create new note in new tmux window" })

-- stylua: ignore
local write_buffer = function() vim.cmd 'wa' end
command("Wa", write_buffer, { nargs = 0 })
command("WA", write_buffer, { nargs = 0 })
