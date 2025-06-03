local config = {
  indent_config = require 'modules.editor.config.snacks_indent',
  zen = require 'modules.editor.config.zen',
}

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      animate = { enabled = true },
      bigfile = { enabled = false },
      bufdelete = { enabled = true }, -- using moll/vim-bbye instead
      dashboard = { enabled = false },
      explorer = { enabled = true },
      gitbrowse = { enabled = true },
      indent = config.indent_config, -- indent highlight animation
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scratch = { enabled = true },
      scroll = { enabled = false }, -- smooth scroll
      statuscolumn = { enabled = true }, -- pretty status coluikn
      terminal = { enabled = false },
      words = { enabled = true },
      zen = config.zen,
    },
    keys = {
      -- stylua: ignore start
      -- { '<leader>Z', function() Snacks.zen.zoom() end, desc = 'Toggle Zoom', },
      { '<leader>Z', function() Snacks.zen() end, desc = 'Toggle Zen Mode', },
      { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Snacks: Rename File', },
      { '<leader>dd', function() Snacks.bufdelete() end, desc = 'Snacks: Bufdelete', },
      { '<leader>fe', function() Snacks.explorer()  end, desc = 'Snacks: explorer', },
      { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Snacks: Git Browse', mode = { 'n', 'v' }, },
      { '<leader>gf', function() Snacks.lazygit.log_file() end, desc = 'Snacks: Lazygit Current File History', },
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'Snacks: Lazygit', },
      { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Snacks: Lazygit Log (cwd)', },
      { '<leader>noh', function() Snacks.notifier.show_history() end, desc = 'Snacks: Notification History', },
      { '<leader>un', function() Snacks.notifier.hide() end, desc = 'Snacks: Dismiss All Notifications', },
      { '<leader>uw', function() Snacks.toggle.option("wrap", {name = "Wrap"}):map("<leader>uw") end, desc = 'Snacks: Toggle wrap', },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Snacks: Prev Reference', mode = { 'n', 't' }, },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Snacks: Next Reference', mode = { 'n', 't' }, },
      -- stylua: ignore end
    },
  },
}
