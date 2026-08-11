local tab = require('lib.tab')
local cmd = require('lib.cmd')

local git_diff = vim.g.icons.git.diff .. 'git diff'
local tabname = git_diff
local last_command = cmd.get_last_command()
if last_command:find('CodeDiff ') then
  tabname = last_command:gsub('CodeDiff ', git_diff .. ' ')
end

tabname = tab.consume_next_name() or tabname
tab.rename(tabname)

vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':tabclose<CR>', {
  desc = 'codediff: close',
})
