local function main_branch()
  local result = vim.system({ 'git', 'symbolic-ref', 'refs/remotes/origin/HEAD' }):wait()
  if result.code == 0 and result.stdout then
    return result.stdout:gsub('^refs/remotes/origin/', ''):gsub('%s+$', '')
  end
  return 'dev'
end

-- fzf-lua git pickers: <CR> opens the commit in a fugitive tab
-- (`:tab Git show <sha>`), replacing codediff's tab diff. Every entry
-- (git log / bcommits / blame) leads with the sha; strip ANSI and the blame
-- boundary `^`.
local function fzf_git_show(selected)
  local line = selected and selected[1]
  if not line then
    return
  end
  line = require('fzf-lua').utils.strip_ansi_coloring(line)
  local commit = (line:match('%S+') or ''):gsub('^%^', '')
  if commit == '' then
    return
  end
  vim.cmd(string.format('tab Git show %s', commit))
end

-- git_bcommits variant: scope fugitive's `git show` to the file the picker
-- was launched from (matches the old per-file CodeDiff).
local function fzf_git_show_file(selected)
  local line = selected and selected[1]
  if not line then
    return
  end
  line = require('fzf-lua').utils.strip_ansi_coloring(line)
  if commit == '' then
    local commit = (line:match('%S+') or ''):gsub('^%^', '')
    return
  end
  vim.cmd(string.format('tab Git show %s -- %%', commit))
end

--- git_commits/git_bcommits/git_blame with a fugitive <CR> action; other
--- default actions (e.g. ctrl-y = yank sha) survive the merge.
---@param picker 'git_commits'|'git_bcommits'|'git_blame'
---@param action fun(selected: table)
---@param o? table extra fzf-lua opts
local function git_fzf_picker(picker, action, o)
  return function()
    require('fzf-lua')[picker](vim.tbl_deep_extend('force', { actions = { enter = action } }, o or {}))
  end
end

--- Snacks picker over `git log -G <query>`; confirming a result opens the
--- commit in a fugitive tab.
---@param opts { global: boolean }
local function git_pickaxe(opts)
  opts = opts or {}
  local is_global = opts.global or false
  local current_file = vim.api.nvim_buf_get_name(0)
  -- Force global if current buffer is invalid
  if not is_global and (current_file == '' or current_file == nil) then
    vim.notify('Buffer is not a file, switching to global search', vim.log.levels.WARN)
    is_global = true
  end

  local title_scope = is_global and 'Global' or vim.fn.fnamemodify(current_file, ':t')
  vim.ui.input({ prompt = 'Git Search (-G) in ' .. title_scope .. ': ' }, function(query)
    if not query or query == '' then
      return
    end

    -- set keyword highlight within Snacks.picker
    vim.fn.setreg('/', query)
    local old_hl = vim.opt.hlsearch
    vim.opt.hlsearch = true

    local args = {
      'log',
      '-G' .. query,
      '-i',
      '--pretty=format:%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset',
      '--abbrev-commit',
      '--date=short',
    }

    if not is_global then
      table.insert(args, '--')
      table.insert(args, current_file)
    end

    Snacks.picker({
      title = 'Git Log: "' .. query .. '" (' .. title_scope .. ')',
      finder = 'proc',
      cmd = 'git',
      args = args,
      layout = 'ivy_split',

      transform = function(item)
        local clean_text = item.text:gsub('\27%[[0-9;]*m', '')
        local hash = clean_text:match('^%S+')
        if hash then
          item.commit = hash
          if not is_global then
            item.file = current_file
          end
        end
        return item
      end,

      preview = 'git_show',
      confirm = function(picker, item)
        picker:close()
        if item.commit then
          vim.cmd(string.format('tab Git show %s', item.commit))
        end
      end,
      format = 'text',

      on_close = function()
        -- remove keyword highlight
        vim.opt.hlsearch = old_hl
        vim.cmd('noh')
      end,
    })
  end)
end

local keymaps = function()
  -- stylua: ignore start
  vim.keymap.set('n', '<leader>G', ":Git<CR>", { desc = 'git: status (fugitive)' })
  vim.keymap.set('n', 'gs', function() require("fzf-lua").git_status() end, { desc = 'git: status (fzf)' })
  vim.keymap.set('n', '<leader>gs', ":Git diff<CR>", { desc = 'git: diff' })
  vim.keymap.set('n', '<leader>gl', git_fzf_picker('git_commits', fzf_git_show), { desc = 'pickaxe: find_git_log' })
  vim.keymap.set('n', '<leader>gf', git_fzf_picker('git_bcommits', fzf_git_show_file, { follow = true }), { desc = 'pickaxe: find_git_log_file' })
  vim.keymap.set('n', '<leader>gb', git_fzf_picker('git_blame', fzf_git_show), { desc = 'fzf: Git Blame Line' })
  vim.keymap.set('n', '<leader>hs', function() git_pickaxe({ global = false }) end, { desc = 'pickaxe: Git Search (Buffer)' })
  vim.keymap.set('n', '<leader>hS', function() git_pickaxe({ global = true }) end, { desc = 'pickaxe: Git Search (Global)' })
  vim.keymap.set('n', 'gP', ':Git push<CR>', { desc = 'git: push' })
  vim.keymap.set('n', 'gA', function() vim.cmd('tab Git add -p') end, { desc = 'git: Git add -p`', })
  vim.keymap.set('n', 'gR', function() vim.cmd("Git reset %") end, { desc = 'git: Git restore %' })
  vim.keymap.set('n', 'gcA', function() vim.cmd("tab Git commit --amend") end, { desc = 'git: Git commit --amend' })
  vim.keymap.set('n', 'glf', ":Git log -p %<cr>", { desc = 'git: git log % (fugitive)' })
  vim.keymap.set('n', 'gll', ":Git log --name-only -n 20<cr>", { desc = 'git: git log --name-only -n 20 (fugitive)' })
  vim.keymap.set('n', 'glo', ":Git log --oneline -n 20<cr>", { desc = 'git: git log --oneline -n 20 (fugitive)' })

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

  -- The staging flow lives in lib.git so `ga` inside a `:Diff` patch buffer can
  -- run it on the file section under the cursor (after/ftplugin/git.lua).
  vim.keymap.set('n', 'ga', function()
    lib.git.add()
  end, { desc = 'git: git add -p current file' })

  -- git: compare branch with HEAD in a fugitive diff tab
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
        vim.cmd(string.format('tab Git diff %s HEAD', item.text))
      end,
    })
  end, { desc = 'git: diff branch with HEAD' })

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
