local config = {
  indent_config = require 'modules.editor.config.snacks-config',
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
      bufdelete = { enabled = false }, -- using moll/vim-bbye instead
      dashboard = { enabled = false },
      indent = config.indent_config, -- indent highlight animation
      gitbrowse = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scratch = { enabled = true },
      terminal = { enabled = false },
      scroll = { enabled = false }, -- smooth scroll
      statuscolumn = { enabled = true }, -- pretty status coluikn
      words = { enabled = true },
      zen = config.zen,
    },
    keys = {
      -- stylua: ignore start
      { '<leader>noh', function() Snacks.notifier.show_history() end, desc = 'Snacks: Notification History', },
      { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Snacks: Rename File', },
      { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Snacks: Git Browse', mode = { 'n', 'v' }, },
      { '<leader>gf', function() Snacks.lazygit.log_file() end, desc = 'Snacks: Lazygit Current File History', },
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'Snacks: Lazygit', },
      { '<leader>gl', function() Snacks.lazygit.log() end, desc = 'Snacks: Lazygit Log (cwd)', },
      { '<leader>un', function() Snacks.notifier.hide() end, desc = 'Snacks: Dismiss All Notifications', },
      { '<leader>uw', function() Snacks.toggle.option("wrap", {name = "Wrap"}):map("<leader>uw") end, desc = 'Snacks: Toggle wrap', },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Snacks: Next Reference', mode = { 'n', 't' }, },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Snacks: Prev Reference', mode = { 'n', 't' }, },
      { '<leader>Z', function() Snacks.zen() end, desc = 'Toggle Zen Mode', },
      -- { '<leader>Z', function() Snacks.zen.zoom() end, desc = 'Toggle Zoom', },
      -- stylua: ignore end
    },
  },
}
