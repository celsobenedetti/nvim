local tmux = require('lib.tmux')

map('n', 'ga', function()
  local file = vim.fn.expand('%')

  local hunks = require('gitsigns').get_hunks(0)

  -- file is not in git
  if hunks == nil then
    vim.system({ 'git', 'add', file })
    Snacks.notify.info(string.format('Added: `%s`', file), {
      title = 'Git',
      icon = '',
      style = 'fancy',
    })
    return
  end

  if #hunks == 0 then
    Snacks.notify.warn(string.format('No changes: `%s`', file), {
      title = 'Git',
      icon = '',
      style = 'fancy',
    })
    return
  end

  local cmd = string.format('git add -p %s', file)
  tmux.neww(cmd, { name = ' add' })
end, {
  desc = 'git: tmux neww `git add -p %`',
})

map('n', 'gA', function()
  tmux.neww('git add -p', { name = ' add' })
end, {
  desc = 'git: tmux neww `git add -p`',
})

map('n', 'gR', function()
  tmux.neww('git restore -p', { name = ' restore' })
end, {
  desc = 'git: tmux neww `git restore -p`',
})

map('n', 'gC', function()
  tmux.neww('commit.sh', { name = ' commit' })
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
