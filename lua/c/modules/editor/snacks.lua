---@class snacks.indent.Config
local indent_config = {
  indent = {
    priority = 1,
    enabled = true, -- enable indent guides
    char = '│',
    only_scope = false, -- only show indent guides of the scope
    only_current = false, -- only show indent guides in the current window
    hl = 'SnacksIndent', ---@type string|string[] hl groups for indent guides
  },
  animate = {
    enabled = vim.fn.has 'nvim-0.10' == 1,
    style = 'out',
    easing = 'linear',
    duration = {
      step = 20, -- ms per step
      total = 500, -- maximum duration
    },
  },
  scope = {
    enabled = true, -- enable highlighting the current scope
    priority = 200,
    char = '│',
    underline = false, -- underline the start of the scope
    only_current = true, -- only show scope in the current window
    hl = 'SnacksIndentScope', ---@type string|string[] hl group for scopes
  },
  chunk = {
    enabled = false,
    only_current = false,
    priority = 200,
    hl = 'SnacksIndentChunk', ---@type string|string[] hl group for chunk scopes
    char = {
      corner_top = '┌',
      corner_bottom = '└',
      -- corner_top = "╭",
      -- corner_bottom = "╰",
      horizontal = '─',
      vertical = '│',
      arrow = '>',
    },
  },
  blank = {
    char = ' ',
    hl = 'SnacksIndentBlank', ---@type string|string[] hl group for blank spaces
  },
  filter = function(buf)
    return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ''
  end,
}

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      animate = { enabled = true },
      bigfile = { enabled = true },
      bufdelete = { enabled = false }, -- using moll/vim-bbye instead
      dashboard = { enabled = true },
      indent = indent_config, -- indent highlight animation
      gitbrowse = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scratch = { enabled = true },
      terminal = { enabled = false },
      scroll = { enabled = false }, -- smooth scroll
      statuscolumn = { enabled = true }, -- pretty status coluikn
      words = { enabled = true },
      zen = {
        win = {
          style = {
            enter = true,
            fixbuf = false,
            minimal = false,
            width = 120,
            height = 0,
            backdrop = { transparent = true, blend = 10 },
            keys = { q = false },
            zindex = 40,
            wo = {
              winhighlight = 'NormalFloat:Normal',
            },
          },
        },
      },
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
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Snacks: Next Reference', mode = { 'n', 't' }, },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Snacks: Prev Reference', mode = { 'n', 't' }, },
      { '<leader>Z', function() Snacks.zen() end, desc = 'Toggle Zen Mode', },
      -- { '<leader>Z', function() Snacks.zen.zoom() end, desc = 'Toggle Zoom', },
      -- stylua: ignore end
    },
  },
}
