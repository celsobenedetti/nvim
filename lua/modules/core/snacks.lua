local cwd = require('lib.cwd')

local function dotfiles()
  Snacks.picker.files({ dirs = { '~/.dotfiles', '~/.config/nvim' }, title = 'dotfiles', hidden = true })
end

local function cd()
  Snacks.picker.zoxide({ confirm = { 'cd', 'lcd', 'close' }, title = 'cd (zoxide)' })
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
  Snacks.picker.files({ cwd = '~/notes', title = 'notes', layout = 'ivy_split' })
end

return {
  'folke/snacks.nvim',
  lazy = false,
  ---@type snacks.Config
  opts = {
    terminal = { enabled = true },
    words = { enabled = true },
    notify = { enabled = true },
    indent = { enabled = true },
    input = { enabled = false },

    notifier = {
      top_down = false,
      enabled = true,
      -- margin = {
      --   top = 0,
      --   right = 100, -- A large value to push it to the left edge
      --   bottom = 0,
      -- },
      filter = function(notification)
        local ignore = {
          'File is too large to send to server', -- thank you supermaven, please stfu
          'Request textDocument/diagnostic failed with message: No ESLint configuration found in', -- err when eslint is not available
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
      -- theme = { selectedLineBgColor = { bg = 'CursorLine' } },
      win = { width = 0, height = 0 },
    },

    picker = {
      enabled = true,
      exclude = vim.g.ignore.grep,
      layout = 'ivy_split',
      win = {
        input = {
          keys = {
            ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
            ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
            ['<c-y>'] = { 'yank', mode = { 'n', 'i' } },
            ['<c-l>'] = { 'yank', mode = { 'n', 'i' } }, -- TODO: this should actually insert the text to buffer
            ['<a-q>'] = { 'qflist', mode = { 'n', 'i' } },
            -- ['s'] = { 'flash' },
          },
        },
      },
      layouts = {
        select = {
          hidden = { 'preview' },
          layout = {
            backdrop = false,
            width = 0.5,
            min_width = 80,
            max_width = 100,
            height = 0.4,
            min_height = 2,
            box = 'vertical',
            border = true,
            title = '{title}',
            title_pos = 'center',
            { win = 'input', height = 1, border = 'bottom' },
            { win = 'list', border = 'none' },
            -- { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
          },
        },
      },

      sources = {
        explorer = {
          auto_close = false,
          ignored = true,
          exclude = vim.g.ignore.explorer,
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
  },
  keys = {
    -- stylua: ignore start
    -- TODO: figure out cwd in terminal, if opening file with different cwd from root
    -- keymap won't work inside terminal, opening a second terminal instead of toggling the first
    -- { '<c-/>', function() Snacks.terminal.toggle() end, desc = 'snacks: terminal toggle', mode = { 'n', 't' }, },
    { '<leader>no', function() Snacks.picker.notifications() end, desc = 'snacks: notification history', },
    { '<leader>rg', function() Snacks.picker.grep({layout= "ivy_split"}) end, desc = 'snacks: grep', },
    { '<leader>rG', function() Snacks.picker.grep({layout= "ivy_split", hidden = true}) end, desc = 'snacks: grep (all)', },
    { '<leader>dd', function() Snacks.bufdelete() end, desc = 'snacks: delete buffer', },
    { '<leader>dot', dotfiles, desc = 'snacks: search dotfiles', },
    { '<leader>of', function() Snacks.picker.files { cwd = '~/notes', title = ' Org Files', ft = 'org' } end, desc = 'snacks: search orgifles', },
    { '<leader>sn', notes, desc = 'snacks: search all notes', },
    { '<leader>fF', function() Snacks.picker.git_files() end, desc = 'snacks: Find Files (git-files)', },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'snacks: Rename File', },
    { '<leader>lgl', function() Snacks.lazygit.log() end, desc = 'snacks: Lazygit Log (cwd)', },
    { '<leader>fE', function() Snacks.explorer { cwd = cwd.root() } end, desc = 'snacks: Explorer Snacks (root dir)', },
    { '<leader>dab', function() Snacks.bufdelete.all() end, desc = 'snacks: delete all buffers', },
    { '<leader>cd', cd, desc = 'snacks: zoxide (cd)', },
    { '<leader>ws', workspace, desc = 'snacks: workspace (zoxide)', },
    { '<leader>zo', function()Snacks.picker.zoxide({title="session (zoxide)"})end, desc = 'snacks: zoxide (session)', },

    { '♣', Explorer, desc = 'snacks: explorer', }, -- C-S-E set in terminal
    { '<leader>fe', function()Snacks.explorer()end, desc = 'snacks: explorer (fe)', },
    { '<leader>co', function() Snacks.picker.commands({layout ="select"}) end, desc = 'snacks: Commands', },
    { '<leader>sC', function() Snacks.picker.command_history({layout="select" }) end, desc = 'snacks: Command History', },
    { 'grs', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'snacks: snacks: References', },


    -- -- find
    { '<leader>,', function() Snacks.picker.buffers({layout="ivy_split"}) end, desc = 'snacks: Buffers', },
    { '<leader><leader>', function() Snacks.picker.buffers({layout="ivy_split"}) end, desc = 'snacks: Buffers', },
    { '<leader><', function() Snacks.picker.buffers { layout="ivy_split",hidden = true, nofile = true } end, desc = 'snacks: Buffers (all)', },
    { '<C-p>', function() Snacks.picker.smart({layout="select", title=""}) end, desc = 'snacks: Smart picker', mode = {'n'} },

    { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'snacks: Find Files (git-files)', },
    { '<leader>sr', function() Snacks.picker.recent() end, desc = 'snacks: Recent', },
    { '<leader>sR', function() Snacks.picker.recent { filter = { cwd = true } } end, desc = 'snacks: Recent (cwd)', },
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'snacks: Projects', },
    -- -- git
    { '<leader>gD', function() Snacks.picker.git_diff { base = 'origin', group = true } end, desc = 'snacks: Git Diff (origin)', },
    { '<leader>gS', function() Snacks.picker.git_stash({layout="ivy_split"}) end, desc = 'snacks: Git Stash', },
    -- { '<leader>gi', function() Snacks.picker.gh_issue() end, desc = 'snacks: GitHub Issues (open)', },
    -- { '<leader>gI', function() Snacks.picker.gh_issue { state = 'all' } end, desc = 'snacks: GitHub Issues (all)', },
    { '<leader>gp', function() Snacks.picker.gh_pr() end, desc = 'snacks: GitHub Pull Requests (open)', },
    { '<leader>gP', function() Snacks.picker.gh_pr { state = 'all' } end, desc = 'snacks: GitHub Pull Requests (all)', },
    -- -- Grep
    { '<leader>/', function() Snacks.picker.lines() end, desc = 'snacks: Buffer Lines', },
    { '<leader>sB', function() Snacks.picker.grep_buffers({layout="ivy_split"}) end, desc = 'snacks: Grep Open Buffers', },
    { '<leader>sla', function() Snacks.picker.lazy() end, desc = 'snacks: Search for Plugin Spec', },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'snacks: Registers', },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'snacks: Search History', },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'snacks: Autocmds', },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'snacks: Diagnostics', },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'snacks: Buffer Diagnostics', },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'snacks: Help Pages', },
    { '<leader>si', function() Snacks.picker.icons() end, desc = 'snacks: Icons', },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'snacks: Jumps', },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'snacks: Keymaps', },
    { '<leader>slo', function() Snacks.picker.loclist() end, desc = 'snacks: Location List', },
    { '<leader>sM', function() Snacks.picker.man() end, desc = 'snacks: Man Pages', },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'snacks: Marks', },
    { '<leader>pr', function() Snacks.picker.resume() end, desc = 'snacks: Resume', },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'snacks: Quickfix List', },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'snacks: Undotree', },
    -- ui
    { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'snacks: Colorschemes', },
    { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols {} end, desc = 'snacks: LSP Workspace Symbols', },
    { 'z=', function() Snacks.picker.spelling () end, desc = 'snacks: picker: spelling', },


    -- { '<leader>gg', function() Snacks.lazygit { cwd = cwd.root() } end, desc = 'snacks: Lazygit (Root Dir)', },
    { '<leader>gG', function() Snacks.lazygit() end, desc = 'snacks: Lazygit (cwd)', },
    -- lsp
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'snacks: Next Reference', },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'snacks: Prev Reference', },
    -- TODO: decide which of these is good
    -- { 'gb', function() Snacks.picker.git_log_line() end, { desc = 'snacks: Git Blame Line' }, },
    -- { 'gl', function() Snacks.picker.git_log_line() end, { desc = 'Git Blame Line' }, },
    { 'gB', function() Snacks.gitbrowse();  end, { desc = 'snacks: Git Browse (open)' }, },
    { 'gY', function()
      Snacks.gitbrowse { open = function(url) vim.fn.setreg('+', url) end, notify = false, }
      Snacks.notify('Copied permalink to clipboard: ' .. vim.fn.getreg('+'))
    end, { desc = 'snacks: Git Browse (copy)', mode = { 'n', 'x' } }, },

    { '<leader>sH', function() Snacks.picker.highlights({layout = 'select'}) end, desc = 'snacks: Highlights', },
    -- stylua: ignore end
  },
}
