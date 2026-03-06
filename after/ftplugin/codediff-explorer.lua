local tabname = nil
local git_diff = vim.g.icons.git.diff .. 'git diff'
local last_command = vim.fn.histget('cmd', -1)
if last_command:find('CodeDiff ') then
  tabname = last_command:gsub('CodeDiff ', git_diff .. ' ')
end
tabname = tabname or git_diff

if vim.g.tabname then
  tabname = vim.g.tabname
  vim.g.tabname = nil
end

vim.g.fn.rename_tab(tabname)

vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':tabclose<CR>', {
  desc = 'codediff: close',
})
