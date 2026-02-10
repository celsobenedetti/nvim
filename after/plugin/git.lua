local tmux = require('lib.tmux')

map('n', 'ga', function()
  local cmd = string.format('git add -p %s', vim.fn.expand('%'))
  tmux.neww(cmd)
end, {
  desc = 'git: tmux neww `git add -p %`',
})

map('n', 'gA', function()
  tmux.neww('git add -p')
end, {
  desc = 'git: tmux neww `git add -p`',
})

map('n', 'gR', function()
  tmux.neww('git restore -p')
end, {
  desc = 'git: tmux neww `git restore -p`',
})

map('n', 'gC', function()
  tmux.neww('commit.sh')
end, {
  desc = 'git: tmux neww `commit.sh`',
})

map('n', '<leader>gs', function()
  local tabs = vim.api.nvim_list_tabpages()
  local ok, tabname = pcall(require, 'tabby.feature.tab_name')
  if not ok then
    Snacks.notify.warn("can't rename tab: tabby.nvim not installed")
    return
  end

  for _, tabid in ipairs(tabs) do
    if tabname.get(tabid):find('git status') then
      vim.cmd('tabnext')
      return
    end
  end

  vim.cmd('CodeDiff')
end, { desc = 'git: (codediff) git status' })

map('n', 'gs', function()
  Snacks.picker.git_status({ layout = 'ivy_split' })
end, { desc = 'git: (snacks) git Status' })
