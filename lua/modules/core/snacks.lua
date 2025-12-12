local cwd = require('lib.cwd')

return {
  'folke/snacks.nvim',
  lazy = false,
  opts = {
    terminal = { enabled = true },
    words = { enabled = true },
    notify = { enabled = true },
    indent = { enabled = true },

    notifier = {
      enabled = true,
      filter = function(notification)
        local ignore = {
          'File is too large to send to server', -- thank you supermaven, please stfu
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
          win = {
            list = {
              keys = {
                ['Z'] = function()
                  vim.cmd('q')
                end,
              },
            },
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
  },
  keys = {
    -- stylua: ignore start
    { '<c-_>', function() Snacks.terminal(nil, { cwd = cwd.root() }) end, desc = 'Terminal (Root Dir)', mode = { 'n', 't' }, },
    { '<leader>no', function() Snacks.picker.notifications() end, desc = 'Notification History', },
    { '<leader>rg', function() Snacks.picker.grep() end, desc = 'Grep', },
    { '<leader>rG', function() Snacks.picker.grep({hidden = true}) end, desc = 'Grep (all)', },
    { '<leader>dd', function() Snacks.bufdelete() end, desc = 'delete buffer', },
    { '<leader>dot', function() Snacks.picker.files { cwd = '~/.dotfiles', title = '~/.dotfiles', hidden = true } end, desc = 'search dotfiles', },
    { '<leader>of', function() Snacks.picker.files { cwd = '~/notes', title = ' Org Files', ft = 'org' } end, desc = 'search orgifles', },
    { '<leader>fn', function() Snacks.picker.files { cwd = '~/notes', title = 'All notes' } end, desc = 'search all notes', },
    { '<leader>rs', function() require('persistence').load() end, desc = 'Restore Session', },
    { '<leader>sS', function() require('persistence').select() end, desc = 'Select Session', },
    { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore Last Session', },
    { '<leader>qd', function() require('persistence').stop() end, desc = "Don't Save Current Session", },
    { '<leader>fF', function() Snacks.picker.git_files() end, desc = 'Find Files (git-files)', },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File', },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Snacks: Lazygit Log (cwd)', },
    { '<leader>fE', function() Snacks.explorer { cwd = cwd.root() } end, desc = 'Explorer Snacks (root dir)', },
    { '<C-E>', function() Snacks.explorer.open { exclude = vim.g.ignore.explorer, ignored = true } end, desc = 'Snacks: explorer', },
    { '<leader>en', function() Snacks.explorer.open { cwd = '~/notes' } end, desc = 'Snacks: explorer notes', },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = 'Commands', },
    { '<leader>sC', function() Snacks.picker.command_history() end, desc = 'Command History', },
    { 'grs', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References', },


    -- -- find
    { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers', },
    { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers', },
    { '<leader>fB', function() Snacks.picker.buffers { hidden = true, nofile = true } end, desc = 'Buffers (all)', },
    { '<leader><space>', function() Snacks.notify.warn('VSCode: please use <C-p> instead of <leader><space>', { title = 'VSCode' }) end, desc = 'Find Files (Root Dir)', },
    { '<leader>ff', function() Snacks.notify.warn('VSCode: please use <C-p> instead of <leader>ff', { title = 'VSCode' }) end, desc = 'Find Files (Root Dir)', },
    { '<C-p>', function() Snacks.picker.files() end, desc = 'Find Files (Root Dir)', },

    { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'Find Files (git-files)', },
    { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Recent', },
    { '<leader>fR', function() Snacks.picker.recent { filter = { cwd = true } } end, desc = 'Recent (cwd)', },
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
    { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume', },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List', },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undotree', },
    -- ui
    { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes', },
    { '<leader>ws', function() Snacks.picker.lsp_workspace_symbols {} end, desc = 'LSP Workspace Symbols', },

    -- set in allacrity
    -- { '♠', function() Snacks.picker.lsp_symbols {} end, desc = 'LSP Symbols', }, -- C-S-O
    { '<leader>ss', function() Snacks.notify.warn('VSCode: please use <C-O> instead of <leader>ss', { title = 'VSCode' }) end, desc = 'Search for Plugin Spec', },

    { '<leader>gg', function() Snacks.lazygit { cwd = cwd.root() } end, desc = 'Lazygit (Root Dir)', },
    { '<leader>gG', function() Snacks.lazygit() end, desc = 'Lazygit (cwd)', },
    -- lsp
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', },
    -- TODO: decide which of these is good
    { 'gb', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    { 'gl', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    { 'gB', function() Snacks.gitbrowse();  end, { desc = 'Git Browse (open)' }, },
    { 'gy', function()
      Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false, }
      Snacks.notify('Copied permalink to clipboard: ' .. vim.fn.getreg('+'))
    end, { desc = 'Git Browse (copy)', mode = { 'n', 'x' } }, },
    { '<leader>gf', function() Snacks.picker.git_log_file() end, { desc = 'Git Current File History' }, },
    { '<leader>gl', function() Snacks.picker.git_log { cwd = cwd.root() } end, { desc = 'Git Log' }, },

    -- stylua: ignore end
  },
}
