local tmux = require('lib.tmux')

map('n', 'ga', function()
  local cmd = string.format('git add -p %s', vim.fn.expand('%'))
  tmux.neww(cmd)
end, {
  desc = 'git: tmux neww `add.sh %`',
})
map('n', 'gC', function()
  tmux.neww('commit.sh -y')
end, {
  desc = 'git: tmux neww `commit.sh`',
})

map('n', 'gs', function()
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
end, { desc = 'git: git status' })
