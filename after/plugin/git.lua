-- stylua: ignore start
map('n', 'gs', function() Snacks.picker.git_status({ layout = 'ivy_split' }) end, { desc = 'git: (snacks) git Status' })
map('n', 'gp', ':Git push<CR>', { desc = 'git: push' })
map('n', 'gA', function() vim.cmd('Git add -p') end, { desc = 'git: Git add -p`', })
map('n', 'gR', function() vim.cmd("Git restore -p") end, { desc = 'git: Git restore -p' })
-- stylua: ignore end

map('n', 'gC', function()
  local result = vim.system({ 'git', 'diff', '--staged', '--name-only' }):wait()
  local has_staged = result.stdout ~= nil and result.stdout ~= ''
  if has_staged then
    vim.cmd('Git commit')
  else
    vim.cmd('Git commit --amend')
  end
end, { desc = 'git: Git commit (or amend if nothing staged)' })

map('n', 'ga', function()
  local file = vim.fn.expand('%')
  local hunks = require('gitsigns').get_hunks(0)

  -- file is not in git
  if hunks == nil then
    if vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'nofile' then
      Snacks.notify.warn('not a git file', { title = 'Git', icon = '', style = 'fancy' })
      return
    end

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

  vim.g.tabname = ' git status'
  vim.cmd('CodeDiff')
end, { desc = 'git: (codediff) git status' })
