local lib = require('lib')

local function main_branch()
  local result = vim.system({ 'git', 'symbolic-ref', 'refs/remotes/origin/HEAD' }):wait()
  if result.code == 0 and result.stdout then
    return result.stdout:gsub('^refs/remotes/origin/', ''):gsub('%s+$', '')
  end
  return 'dev'
end

local keymaps = function()
-- stylua: ignore start
map('n', 'gs', function() require("fzf-lua").git_status(lib.fzf.e()) end, { desc = 'git: (snacks) git Status' })
map('n', 'gp', ':Git push<CR>', { desc = 'git: push' })
map('n', 'gA', function() vim.cmd('tab Git add -p') end, { desc = 'git: Git add -p`', })
map('n', 'gR', function() vim.cmd("tab Git restore -p") end, { desc = 'git: Git restore -p ' })

map('n','<leader>gd', function()vim.cmd('vertical Git diff ' .. main_branch() .. ' -- %')end, {desc ="git: Git diff main -- %"})
  -- stylua: ignore end

  map('n', 'gC', function()
    local cwd = vim.fn.expand('%:p:h')
    local result = vim.system({ 'git', 'diff', '--staged', '--name-only' }, { cwd = cwd }):wait()
    local has_staged = result.stdout ~= nil and result.stdout ~= ''
    local cmd = 'tab Git commit'
    if not has_staged then
      cmd = cmd .. ' --amend'
    end
    vim.cmd(cmd)
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

    vim.cmd('tab Git add -p %')
  end, { desc = 'git: git add -p current file' })

  map('n', '<leader>gs', function()
    local tab = require('lib.tab')
    if tab.find('git status') then
      vim.cmd('tabnext')
      return
    end

    tab.set_next_name(' git status')
    vim.cmd('CodeDiff')
  end, { desc = 'git: (codediff) git status' })

  -- git: CodeDiff with branch picker
  map('n', '<leader>gD', function()
    local branches = vim.fn.systemlist('git branch -a --sort=-committerdate')
    if vim.v.shell_error ~= 0 then
      Snacks.notify.error('Not a git repository')
      return
    end

    local items = {}
    for _, branch in ipairs(branches) do
      local name = branch:match('^%s*%*?%s*(.+)$')
      if name then
        local is_current = branch:match('^%s*%*') ~= nil
        table.insert(items, {
          text = name,
          current = is_current,
        })
      end
    end

    if #items == 0 then
      Snacks.notify.warn('No branches found')
      return
    end

    Snacks.picker.pick({
      layout = 'select',
      title = 'git diff: compare branch with HEAD',
      items = items,
      format = function(item)
        if item.current then
          return { { '* ', 'DiagnosticOk' }, { item.text } }
        end
        return { { '  ' }, { item.text } }
      end,
      confirm = function(picker, item)
        picker:close()
        require('lib.tab').set_next_name(string.format('%sgit diff %s HEAD', vim.g.icons.git.diff, item.text))
        vim.cmd(string.format('CodeDiff %s HEAD', item.text))
      end,
    })
  end, { desc = 'CodeDiff: compare branch with HEAD' })

  vim.keymap.set('n', vim.g.keys['<C-S-O>'], function()
    require('fzf-lua').lsp_document_symbols()
  end)
end

keymaps()
