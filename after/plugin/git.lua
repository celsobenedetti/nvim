-- stylua: ignore start
map('n', 'gs', function() Snacks.picker.git_status({ layout = 'ivy_split' }) end, { desc = 'git: (snacks) git Status' })
map('n', 'gp', ':Compile git push<CR>', { desc = 'git: push' })
map('n', 'gC', function() vim.cmd('Git commit') end, { desc = 'git: Git commit' })
map('n', 'gA', function() vim.cmd('Git add -p') end, { desc = 'git: Git add -p`', })
map('n', 'gR', function() vim.cmd("Git restore -p") end, { desc = 'git: Git restore -p' })
-- stylua: ignore end

map('n', 'ga', function()
  local file = vim.fn.expand('%')
  local hunks = require('gitsigns').get_hunks(0)

  -- file is not in git
  if hunks == nil then
    vim.system({ 'git', 'add', file })
    Snacks.notify.info(string.format('Added: `%s`', file), { title = 'Git', icon = '', style = 'fancy' })
    return
  end

  if #hunks == 0 then
    Snacks.notify.warn(string.format('No changes: `%s`', file), { title = 'Git', icon = '', style = 'fancy' })
    return
  end

  vim.cmd('Git add -p %')
end, { desc = 'git: git add -p current file' })

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
