local exclude = { '*.org_archive' }
local cwd = require 'lib.cwd'

return {
  'folke/snacks.nvim',
  lazy = false,
  keys = {
    {
      '<c-_>',
      function()
        Snacks.terminal(nil, { cwd = cwd.root() })
      end,
      desc = 'Terminal (Root Dir)',
      mode = { 'n', 't' },
    },
    {
      '<leader>no',
      function()
        Snacks.picker.notifications()
      end,
      desc = 'Notification History',
    },
    {
      '<leader>rg',
      function()
        Snacks.picker.grep()
      end,
      desc = 'Grep',
    },
    {
      '<leader>dd',
      function()
        Snacks.bufdelete()
      end,
      desc = 'delete buffer',
    },
    {
      '<leader>dot',
      function()
        Snacks.picker.files { cwd = '~/.dotfiles', title = '~/.dotfiles', hidden = true }
      end,
      desc = 'search dotfiles',
    },
    {
      '<leader>of',
      function()
        Snacks.picker.files { cwd = '~/notes', title = ' Org Files', ft = 'org' }
      end,
      desc = 'search orgifles',
    },
    {
      '<leader>fn',
      function()
        Snacks.picker.files { cwd = '~/notes', title = 'All notes' }
      end,
      desc = 'search all notes',
    },
    {
      '<leader>rs',
      function()
        require('persistence').load()
      end,
      desc = 'Restore Session',
    },
    {
      '<leader>qS',
      function()
        require('persistence').select()
      end,
      desc = 'Select Session',
    },
    {
      '<leader>ql',
      function()
        require('persistence').load { last = true }
      end,
      desc = 'Restore Last Session',
    },
    {
      '<leader>qd',
      function()
        require('persistence').stop()
      end,
      desc = "Don't Save Current Session",
    },
    {
      '<leader>fF',
      function()
        Snacks.picker.git_files()
      end,
      desc = 'Find Files (git-files)',
    },
    {
      '<leader>cR',
      function()
        Snacks.rename.rename_file()
      end,
      desc = 'Rename File',
    },
    {
      '<leader>gl',
      function()
        Snacks.lazygit.log()
      end,
      desc = 'Snacks: Lazygit Log (cwd)',
    },
    {
      '<leader>fE',
      function()
        Snacks.explorer { cwd = cwd.root() }
      end,
      desc = 'Explorer Snacks (root dir)',
    },
    {
      '<leader>fe',
      function()
        Snacks.explorer.open { exclude = exclude, ignored = true }
      end,
      desc = 'Snacks: explorer',
    },
    {
      '<leader>e',
      function()
        Snacks.explorer.open { exclude = exclude, ignored = true }
      end,
      desc = 'Snacks: explorer',
    },
    {
      '<leader>en',
      function()
        Snacks.explorer.open { cwd = '~/notes' }
      end,
      desc = 'Snacks: explorer notes',
    },
    {
      '<leader>sc',
      function()
        Snacks.picker.commands()
      end,
      desc = 'Commands',
    },
    {
      '<leader>sC',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      'grs',
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = 'References',
    },
    {
      '<leader>ff',
      function()
        Snacks.picker.files { hidden = require('lib.cwd').matches { 'dotfiles' } }
      end,
      desc = 'Find Files (Root Dir)',
    },
    {
      '<leader>,',
      function()
        Snacks.picker.buffers()
      end,
      desc = 'Buffers',
    },
    {
      '<leader>/',
      function()
        Snacks.picker.grep()
      end,
      desc = 'Grep (Root Dir)',
    },
    {
      '<leader>:',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      '<leader><space>',
      function()
        Snacks.picker.files()
      end,
      desc = 'Find Files (Root Dir)',
    },
    {
      '<leader>n',
      function()
        Snacks.picker.notifications()
      end,
      desc = 'Notification History',
    },
    -- -- find
    {
      '<leader>fb',
      function()
        Snacks.picker.buffers()
      end,
      desc = 'Buffers',
    },
    {
      '<leader>fB',
      function()
        Snacks.picker.buffers { hidden = true, nofile = true }
      end,
      desc = 'Buffers (all)',
    },
    {
      '<leader>ff',
      function()
        Snacks.picker.files()
      end,
      desc = 'Find Files (Root Dir)',
    },
    {
      '<leader>fF',
      function()
        Snacks.picker.files { cwd = cwd.root() }
      end,
      desc = 'Find Files (cwd)',
    },
    {
      '<leader>fg',
      function()
        Snacks.picker.git_files()
      end,
      desc = 'Find Files (git-files)',
    },
    {
      '<leader>fr',
      function()
        Snacks.picker.oldfiles()
      end,
      desc = 'Recent',
    },
    {
      '<leader>fR',
      function()
        Snacks.picker.recent { filter = { cwd = true } }
      end,
      desc = 'Recent (cwd)',
    },
    {
      '<leader>fp',
      function()
        Snacks.picker.projects()
      end,
      desc = 'Projects',
    },
    -- -- git
    {
      '<leader>gd',
      function()
        Snacks.picker.git_diff()
      end,
      desc = 'Git Diff (hunks)',
    },
    {
      '<leader>gD',
      function()
        Snacks.picker.git_diff { base = 'origin', group = true }
      end,
      desc = 'Git Diff (origin)',
    },
    {
      '<leader>gs',
      function()
        Snacks.picker.git_status()
      end,
      desc = 'Git Status',
    },
    {
      '<leader>gS',
      function()
        Snacks.picker.git_stash()
      end,
      desc = 'Git Stash',
    },
    {
      '<leader>gi',
      function()
        Snacks.picker.gh_issue()
      end,
      desc = 'GitHub Issues (open)',
    },
    {
      '<leader>gI',
      function()
        Snacks.picker.gh_issue { state = 'all' }
      end,
      desc = 'GitHub Issues (all)',
    },
    {
      '<leader>gp',
      function()
        Snacks.picker.gh_pr()
      end,
      desc = 'GitHub Pull Requests (open)',
    },
    {
      '<leader>gP',
      function()
        Snacks.picker.gh_pr { state = 'all' }
      end,
      desc = 'GitHub Pull Requests (all)',
    },
    -- -- Grep
    {
      '<leader>sb',
      function()
        Snacks.picker.lines()
      end,
      desc = 'Buffer Lines',
    },
    {
      '<leader>sB',
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = 'Grep Open Buffers',
    },
    -- { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    -- { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    {
      '<leader>sp',
      function()
        Snacks.picker.lazy()
      end,
      desc = 'Search for Plugin Spec',
    },
    -- { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    -- { "<leader>sW", LazyVim.pick("grep_word", { root = false }), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    -- search
    {
      '<leader>s"',
      function()
        Snacks.picker.registers()
      end,
      desc = 'Registers',
    },
    {
      '<leader>s/',
      function()
        Snacks.picker.search_history()
      end,
      desc = 'Search History',
    },
    {
      '<leader>sa',
      function()
        Snacks.picker.autocmds()
      end,
      desc = 'Autocmds',
    },
    {
      '<leader>sc',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      '<leader>sC',
      function()
        Snacks.picker.commands()
      end,
      desc = 'Commands',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = 'Diagnostics',
    },
    {
      '<leader>sD',
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = 'Buffer Diagnostics',
    },
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = 'Help Pages',
    },
    {
      '<leader>sH',
      function()
        Snacks.picker.highlights()
      end,
      desc = 'Highlights',
    },
    {
      '<leader>si',
      function()
        Snacks.picker.icons()
      end,
      desc = 'Icons',
    },
    {
      '<leader>sj',
      function()
        Snacks.picker.jumps()
      end,
      desc = 'Jumps',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = 'Keymaps',
    },
    {
      '<leader>sl',
      function()
        Snacks.picker.loclist()
      end,
      desc = 'Location List',
    },
    {
      '<leader>sM',
      function()
        Snacks.picker.man()
      end,
      desc = 'Man Pages',
    },
    {
      '<leader>sm',
      function()
        Snacks.picker.marks()
      end,
      desc = 'Marks',
    },
    {
      '<leader>sR',
      function()
        Snacks.picker.resume()
      end,
      desc = 'Resume',
    },
    {
      '<leader>sq',
      function()
        Snacks.picker.qflist()
      end,
      desc = 'Quickfix List',
    },
    {
      '<leader>su',
      function()
        Snacks.picker.undo()
      end,
      desc = 'Undotree',
    },
    -- ui
    {
      '<leader>uC',
      function()
        Snacks.picker.colorschemes()
      end,
      desc = 'Colorschemes',
    },
    {
      '<leader>ss',
      function()
        Snacks.picker.lsp_symbols {}
      end,
      desc = 'LSP Symbols',
    },
    {
      '<leader>sS',
      function()
        Snacks.picker.lsp_workspace_symbols {}
      end,
      desc = 'LSP Workspace Symbols',
    },

    {
      '<leader>gg',
      function()
        Snacks.lazygit { cwd = cwd.root() }
      end,
      desc = 'Lazygit (Root Dir)',
    },
    {
      '<leader>gG',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit (cwd)',
    },
    -- lsp
    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      has = 'documentHighlight',
      desc = 'Next Reference',
      enabled = function()
        return Snacks.words.is_enabled()
      end,
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      has = 'documentHighlight',
      desc = 'Prev Reference',
      enabled = function()
        return Snacks.words.is_enabled()
      end,
    },
    {
      '<a-n>',
      function()
        Snacks.words.jump(vim.v.count1, true)
      end,
      has = 'documentHighlight',
      desc = 'Next Reference',
      enabled = function()
        return Snacks.words.is_enabled()
      end,
    },
    {
      '<a-p>',
      function()
        Snacks.words.jump(-vim.v.count1, true)
      end,
      has = 'documentHighlight',
      desc = 'Prev Reference',
      enabled = function()
        return Snacks.words.is_enabled()
      end,
    },
  },

  opts = function(_, opts)
    -- Terminal Mappings
    local function term_nav(dir)
      ---@param self snacks.terminal
      return function(self)
        return self:is_floating() and '<c-' .. dir .. '>'
          or vim.schedule(function()
            vim.cmd.wincmd(dir)
          end)
      end
    end

    opts.lazygit = {
      theme = {
        selectedLineBgColor = { bg = 'CursorLine' },
      },
      -- https://github.com/folke/snacks.nvim/issues/719
      win = {
        -- style = 'dashboard',
        width = 0,
        height = 0,
      },
    }

    -- opts.terminal = {
    --   win = {
    --     keys = {
    --       nav_h = { '<C-h>', term_nav 'h', desc = 'Go to Left Window', expr = true, mode = 't' },
    --       nav_j = { '<C-j>', term_nav 'j', desc = 'Go to Lower Window', expr = true, mode = 't' },
    --       nav_k = { '<C-k>', term_nav 'k', desc = 'Go to Upper Window', expr = true, mode = 't' },
    --       nav_l = { '<C-l>', term_nav 'l', desc = 'Go to Right Window', expr = true, mode = 't' },
    --       hide_slash = { '<C-/>', 'hide', desc = 'Hide Terminal', mode = { 't', 'n' } },
    --       hide_underscore = { '<c-_>', 'hide', desc = 'which_key_ignore', mode = { 't', 'n' } },
    --     },
    --   },
    -- }

    opts.dashboard = { enabled = false }
    opts.picker = opts.picker or {}
    opts.picker.exclude = vim.tbl_extend('keep', opts.picker.exclude or {}, vim.g.grep_ignore or {})

    opts.notify = { enabled = true }
    opts.notifier = {
      enabled = true,
      filter = function(notification)
        -- check if notification.msg
      end,
    }

    opts.picker.win = opts.picker.win or {}
    opts.picker.win.input = opts.picker.win.input or {}
    opts.picker.win.input.keys = vim.tbl_deep_extend('force', opts.picker.win.input.keys or {}, {
      ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
      ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
      ['<c-y>'] = { 'yank', mode = { 'n', 'i' } },
      ['<a-q>'] = { 'qflist', mode = { 'n', 'i' } },
      ['s'] = { 'flash' },
    })

    opts.picker.win.list = opts.picker.win.list or {}
    opts.picker.win.list.keys = opts.picker.win.list.keys or {}
    opts.picker.win.list.keys['ZZ'] = function()
      vim.cmd 'wqa'
    end

    opts.picker.actions = vim.tbl_deep_extend('force', opts.picker.actions or {}, {
      flash = function(picker)
        require('flash').jump {
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
        }
      end,
    })
  end,
}
