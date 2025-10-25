return {

  'folke/snacks.nvim',
  keys = {
    -- stylua: ignore start
    -- { '<c-/>', false },
    { "<leader>no", function() Snacks.picker.notifications() end, desc = "Notification History", },
    { "<leader>rg", function() Snacks.picker.grep() end, desc = "Grep", },
    { "<leader>dd", function() Snacks.bufdelete() end, desc = "delete buffer", },
    { "<leader>dot", function() Snacks.picker.files({cwd="~/.dotfiles", title = "~/.dotfiles", hidden = true, }) end, desc = "search dotfiles", },
    { "<leader>of", function() Snacks.picker.files({cwd="~/notes", title = " Org Files", ft ="org" }) end, desc = "search orgifles", },
    { "<leader>fn", function() Snacks.picker.files({cwd="~/notes", title = "All notes",  }) end, desc = "search all notes", },
    { "<leader>rs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    { "<leader>fF", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", },
    { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Snacks: Lazygit Log (cwd)', },
    { "<leader>fE", function() Snacks.explorer({ cwd = LazyVim.root() }) end, desc = "Explorer Snacks (root dir)", },
    { '<leader>fe', function() Snacks.explorer.open() end, desc = 'Snacks: explorer', },
    { '<leader>en', function() Snacks.explorer.open({cwd = "~/notes"}) end, desc = 'Snacks: explorer notes', },
    { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sC", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "grs", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { '<leader>ff', LazyVim.pick('files', { hidden = require('lib.cwd').matches { 'dotfiles' } }), desc = 'Find Files (Root Dir)',
    -- stylua: ignore end
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

    opts.terminal = {
      win = {
        keys = {
          nav_h = { '<C-h>', term_nav 'h', desc = 'Go to Left Window', expr = true, mode = 't' },
          nav_j = { '<C-j>', term_nav 'j', desc = 'Go to Lower Window', expr = true, mode = 't' },
          nav_k = { '<C-k>', term_nav 'k', desc = 'Go to Upper Window', expr = true, mode = 't' },
          nav_l = { '<C-l>', term_nav 'l', desc = 'Go to Right Window', expr = true, mode = 't' },
          hide_slash = { '<C-/>', 'hide', desc = 'Hide Terminal', mode = { 't', 'n' } },
          hide_underscore = { '<c-_>', 'hide', desc = 'which_key_ignore', mode = { 't', 'n' } },
        },
      },
    }

    opts.dashboard = { enabled = false }
    opts.picker = opts.picker or {}
    opts.picker.exclude = vim.tbl_extend('keep', opts.picker.exclude or {}, vim.g.grep_ignore or {})

    opts.picker.win = opts.picker.win or {}
    opts.picker.win.input = opts.picker.win.input or {}
    opts.picker.win.input.keys = vim.tbl_deep_extend('force', opts.picker.win.input.keys or {}, {
      ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
      ['<a-s>'] = { 'flash', mode = { 'n', 'i' } },
      ['<c-y>'] = { 'yank', mode = { 'n', 'i' } },
      ['<a-q>'] = { 'qflist', mode = { 'n', 'i' } },
      ['s'] = { 'flash' },
    })

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
