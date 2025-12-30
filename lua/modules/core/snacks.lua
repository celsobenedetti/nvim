local cwd = require('lib.cwd')

local function dotfiles()
  Snacks.picker.files({ dirs = { '~/.dotfiles', '~/.config/nvim' }, title = 'dotfiles', hidden = true })
end

local function cd()
  Snacks.picker.zoxide({ confirm = { 'cd', 'close' }, title = 'cd (zoxide)' })
end

local function terminal()
  vim.cmd('tab term')
  vim.g.fn.rename_tab(' bash')
  vim.cmd('startinsert')
end

local function workspace()
  Snacks.picker.zoxide({
    confirm = {
      function(_, item)
        vim.cmd('tabnew')
        if item.file and item.file ~= '' then
          vim.g.fn.rename_tab(vim.fs.basename(item.file))
        end
      end,
      'lcd',
      'close',
    },
    title = 'workspace (zoxide)',
  })
end

local function notes()
  Snacks.picker.files({ cwd = '~/notes', title = 'notes' })
end

return {
  'folke/snacks.nvim',
  lazy = false,
  opts = {
    terminal = { enabled = true },
    words = { enabled = true },
    notify = { enabled = true },
    indent = { enabled = true },
    input = { enabled = false },

    notifier = {
      enabled = true,
      filter = function(notification)
        local ignore = {
          'File is too large to send to server', -- thank you supermaven, please stfu
          'No results found for.*buffers', -- Snacks.picker.buffers when there are no results
        }
        for _, s in ipairs(ignore) do
          if notification.msg:find(s) then
            return false
          end
        end
        return true
      end,
    },

    lazygit = {
      theme = { selectedLineBgColor = { bg = 'CursorLine' } },
      win = { width = 0, height = 0 },
    },

    picker = {
      enabled = true,
      exclude = vim.g.ignore.grep,
      win = {
        input = {
          keys = {
            ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
            ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
            ['<c-y>'] = { 'yank', mode = { 'n', 'i' } },
            ['<a-q>'] = { 'qflist', mode = { 'n', 'i' } },
            -- ['s'] = { 'flash' },
          },
        },
      },

      sources = {
        explorer = {
          auto_close = true,
          ignored = true,
          win = {
            list = {
              keys = {
                ['Z'] = function()
                  vim.cmd('q')
                end,
                ['d'] = 'safe_delete',
              },
            },
          },
          actions = {
            safe_delete = function(picker)
              local selected = picker:selected({ fallback = true })
              local is_root = vim.iter(selected):any(function(s)
                return not s.parent
              end)
              if is_root then
                Snacks.notify.warn("Let's not delete root please")
                return
              end
              picker:action('explorer_del')
            end,
          },
        },
      },

      actions = {
        flash = function(picker)
          require('flash').jump({
            pattern = '^',
            label = { after = { 0, 0 } },
            search = {
              mode = 'search',
              exclude = {
                function(win)
                  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'snacks_picker_list'
                end,
              },
            },
            action = function(match)
              local idx = picker.list:row2idx(match.pos[1])
              picker.list:_move(idx, true, true)
            end,
          })
        end,
      },
    },

    dashboard = {
      enabled = true,
      sections = {
        { section = 'keys', gap = 1, padding = 1 },
      },
      config = function()
        -- dashboard buffer keymaps
        vim.api.nvim_buf_set_keymap(0, 'n', 'f', ':lua Snacks.picker.files()<CR>', {})
      end,
      preset = {
        header = '',
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        -- stylua: ignore start
        keys = {
          { icon = ' ', key = 'c', desc = 'cd', action = cd },
          { icon = '', key = 't', desc = 'terminal', action = terminal },
          { icon = ' ', key = 'r', desc = 'recent', action = ":lua Snacks.picker.recent()" },
          { icon = '', key = 'g', desc = 'git', action = function() if not cwd.is_git_repo() then Snacks.notify.warn('Not in a git repo', { title = 'Git' }) return end Snacks.lazygit() end, },
          { icon = ' ', key = 'e', desc = 'edit', action = ':ene | startinsert' },
          { icon = ' ', key = 's', desc = 'session', action = function()Snacks.picker.zoxide({ title="session (zoxide)" })end },
          { icon = '', key = 'o', desc = 'orgmode', action = function()require('telescope').extensions.orgmode.search_headings()end, },
          { icon = '󰺿 ', key = 'n', desc = 'notes', action = notes },
          { icon = ' ', key = '.', desc = 'config', action = dotfiles },
          { icon = '', key = '/', desc = 'terminal', action = function()Snacks.terminal(nil, { cwd = cwd.root() })end },
          { icon = '󰒲 ', key = 'l', desc = 'lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'm', desc = 'mason', action = ':Mason', enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'q', desc = 'quit', action = ':qa' },
        },
        -- stylua: ignore end
      },
    },
  },
  keys = {
    -- stylua: ignore start
    -- TODO: figure out cwd in terminal, if opening file with different cwd from root
    -- keymap won't work inside terminal, opening a second terminal instead of toggling the first
    -- { '<c-/>', function() Snacks.terminal(nil, { cwd = cwd.root() }) end, desc = 'Terminal (Root Dir)', mode = { 'n', 't' }, },
    { '<c-/>', function() Snacks.terminal() end, desc = 'terminal toggle', mode = { 'n', 't' }, },
    { '<leader>no', function() Snacks.picker.notifications() end, desc = 'Notification History', },
    { '<leader>rg', function() Snacks.picker.grep() end, desc = 'Grep', },
    { '<leader>rG', function() Snacks.picker.grep({hidden = true}) end, desc = 'Grep (all)', },
    { '<leader>dd', function() Snacks.bufdelete() end, desc = 'delete buffer', },
    { '<leader>dot', dotfiles, desc = 'search dotfiles', },
    { '<leader>of', function() Snacks.picker.files { cwd = '~/notes', title = ' Org Files', ft = 'org' } end, desc = 'search orgifles', },
    { '<leader>sn', notes, desc = 'search all notes', },
    { '<leader>fF', function() Snacks.picker.git_files() end, desc = 'Find Files (git-files)', },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File', },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Snacks: Lazygit Log (cwd)', },
    { '<leader>fE', function() Snacks.explorer { cwd = cwd.root() } end, desc = 'Explorer Snacks (root dir)', },
    { '<leader>dab', function() Snacks.bufdelete.all() end, desc = 'Snacks: delete all buffers', },
    { '<leader>cd', cd, desc = 'Snacks: zoxide (cd)', },
    { '<leader>ws', workspace, desc = 'Snacks: workspace (zoxide)', },
    { '<leader>zo', function()Snacks.picker.zoxide({title="session (zoxide)"})end, desc = 'Snacks: zoxide (session)', },

    { '<C-S-E>', Explorer, desc = 'Snacks: explorer', },
    { '<leader>fe', function()Snacks.explorer()end, desc = 'Snacks: explorer (fe)', },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = 'Commands', },
    { '<leader>sC', function() Snacks.picker.command_history() end, desc = 'Command History', },
    { 'grs', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References', },


    -- -- find
    { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers', },
    { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers', },
    { '<leader>fB', function() Snacks.picker.buffers { hidden = true, nofile = true } end, desc = 'Buffers (all)', },
    { '<leader><space>', function() Snacks.notify.warn('VSCode: please use <C-p> instead of <leader><space>', { title = 'VSCode' }) end, desc = 'Find Files (Root Dir)', },
    { '<leader>ff', function() Snacks.notify.warn('VSCode: please use <C-p> instead of <leader>ff', { title = 'VSCode' }) end, desc = 'Find Files (Root Dir)', },
    { '<C-p>', function() Snacks.picker.smart() end, desc = 'Smart picker', },

    { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'Find Files (git-files)', },
    { '<leader>sr', function() Snacks.picker.recent() end, desc = 'Recent', },
    { '<leader>sR', function() Snacks.picker.recent { filter = { cwd = true } } end, desc = 'Recent (cwd)', },
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects', },
    -- -- git
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (hunks)', },
    { '<leader>gD', function() Snacks.picker.git_diff { base = 'origin', group = true } end, desc = 'Git Diff (origin)', },
    { '<leader>gs', function() Snacks.picker.git_status() end, desc = 'Git Status', },
    { '<leader>gS', function() Snacks.picker.git_stash() end, desc = 'Git Stash', },
    -- { '<leader>gi', function() Snacks.picker.gh_issue() end, desc = 'GitHub Issues (open)', },
    -- { '<leader>gI', function() Snacks.picker.gh_issue { state = 'all' } end, desc = 'GitHub Issues (all)', },
    { '<leader>gp', function() Snacks.picker.gh_pr() end, desc = 'GitHub Pull Requests (open)', },
    { '<leader>gP', function() Snacks.picker.gh_pr { state = 'all' } end, desc = 'GitHub Pull Requests (all)', },
    -- -- Grep
    { '<leader>/', function() Snacks.picker.lines() end, desc = 'Buffer Lines', },
    { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers', },
    { '<leader>sp', function() Snacks.picker.lazy() end, desc = 'Search for Plugin Spec', },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers', },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search History', },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds', },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics', },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Buffer Diagnostics', },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages', },
    { '<leader>sH', function() Snacks.picker.highlights() end, desc = 'Highlights', },
    { '<leader>si', function() Snacks.picker.icons() end, desc = 'Icons', },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Jumps', },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps', },
    { '<leader>sl', function() Snacks.picker.loclist() end, desc = 'Location List', },
    { '<leader>sM', function() Snacks.picker.man() end, desc = 'Man Pages', },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks', },
    { '<leader>pr', function() Snacks.picker.resume() end, desc = 'Resume', },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List', },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undotree', },
    -- ui
    { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes', },
    { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols {} end, desc = 'LSP Workspace Symbols', },
    { 'z=', function() Snacks.picker.spelling () end, desc = 'picker: spelling', },


    { '<leader>gg', function() Snacks.lazygit { cwd = cwd.root() } end, desc = 'Lazygit (Root Dir)', },
    { '<leader>gG', function() Snacks.lazygit() end, desc = 'Lazygit (cwd)', },
    -- lsp
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', },
    -- TODO: decide which of these is good
    { 'gb', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    -- { 'gl', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    { 'gB', function() Snacks.gitbrowse();  end, { desc = 'Git Browse (open)' }, },
    { 'gY', function()
      Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false, }
      Snacks.notify('Copied permalink to clipboard: ' .. vim.fn.getreg('+'))
    end, { desc = 'Git Browse (copy)', mode = { 'n', 'x' } }, },
    -- { '<leader>gf', function() Snacks.picker.git_log_file() end, { desc = 'Git Current File History' }, },
    -- { '<leader>gl', function() Snacks.picker.git_log { cwd = cwd.root() } end, { desc = 'Git Log' }, },

    -- stylua: ignore end
  },
}
