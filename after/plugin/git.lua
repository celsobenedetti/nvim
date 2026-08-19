local function main_branch()
  local result = vim.system({ 'git', 'symbolic-ref', 'refs/remotes/origin/HEAD' }):wait()
  if result.code == 0 and result.stdout then
    return result.stdout:gsub('^refs/remotes/origin/', ''):gsub('%s+$', '')
  end
  return 'dev'
end

local keymaps = function()
  -- stylua: ignore start
  vim.keymap.set('n', '<leader>G', ":Git<CR>", { desc = 'git: status (fugitive)' })
  vim.keymap.set('n', 'gs', function() require("fzf-lua").git_status(lib.fzf.e()) end, { desc = 'git: status (fzf)' })
  vim.keymap.set('n', '<leader>gs', ":CodeDiff<CR>", { desc = 'git: status (CodeDiff)' })
  vim.keymap.set('n', 'gP', ':Git push<CR>', { desc = 'git: push' })
  -- vim.keymap.set('n', 'gA', function() vim.cmd('tab Git add -p') end, { desc = 'git: Git add -p`', })
  vim.keymap.set('n', 'gR', function() vim.cmd("tab Git restore -p") end, { desc = 'git: Git restore -p ' })
  vim.keymap.set('n', 'gcA', function() vim.cmd("tab Git commit --amend") end, { desc = 'git: Git commit --amend' })

  vim.keymap.set('n', '<leader>gd', function() vim.cmd('vertical Git diff ' .. main_branch() .. ' -- %') end,
    { desc = "git: Git diff main -- %" })
  -- stylua: ignore end

  vim.keymap.set('n', 'gC', function()
    local cwd = vim.fn.expand('%:p:h')
    local result = vim.system({ 'git', 'diff', '--staged', '--name-only' }, { cwd = cwd }):wait()
    local has_staged = result.stdout ~= nil and result.stdout ~= ''
    local cmd = 'tab Git commit'
    if not has_staged then
      cmd = cmd .. ' --amend'
    end
    vim.cmd(cmd)
  end, { desc = 'git: Git commit (or amend if nothing staged)' })

  vim.keymap.set('n', 'ga', function()
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

  -- git: CodeDiff with branch picker
  vim.keymap.set('n', '<leader>gD', function()
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
        lib.tab.set_next_name(string.format('%sgit diff %s HEAD', config.icons.git.diff, item.text))
        vim.cmd(string.format('CodeDiff %s HEAD', item.text))
      end,
    })
  end, { desc = 'CodeDiff: compare branch with HEAD' })

  vim.keymap.set('n', '<leader>pr', function()
    vim.cmd.tabnew()
    vim.cmd.term('gh pr view')
  end, { desc = 'gh: PR view (terminal in new tab)' })

  -- git: Git log -L for the current line or visual selection
  local function git_relative_path()
    local root = vim.fs.root(0, '.git')
    if not root then
      Snacks.notify.warn('not a git repo', { title = 'Git', icon = '', style = 'fancy' })
      return nil
    end
    local file = vim.fn.expand('%:p')
    if file == '' then
      Snacks.notify.warn('buffer has no file', { title = 'Git', icon = '', style = 'fancy' })
      return nil
    end
    local prefix = root:gsub('/+$', '') .. '/'
    if file:sub(1, #prefix) == prefix then
      return file:sub(#prefix + 1)
    end
    return file
  end

  local function git_log_line_range()
    local path = git_relative_path()
    if not path then
      return
    end
    local start_line, end_line = lib.visual.get_region()
    if not start_line or not end_line then
      start_line = vim.fn.line('.')
      end_line = start_line
    end
    vim.cmd(string.format('Git log -L %d,%d:%s', start_line, end_line, path))
  end

  vim.keymap.set({ 'n', 'v' }, 'gL', git_log_line_range, { desc = 'git: Git log -L line range' })

  if config.keys['<C-S-O>'] then
    vim.keymap.set('n', config.keys['<C-S-O>'], function()
      require('fzf-lua').lsp_document_symbols()
    end)
  end
end

keymaps()
