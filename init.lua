require 'c.core.config'

require('lazy').setup({
  { import = 'c.core.plugins' },

  { import = 'c.modules.editor' },
  { import = 'c.modules.dap' },
  { import = 'c.modules.typescript', ft = { 'typescript', 'typescriptreact' } },
  { import = 'c.modules.lang.markdown', ft = { 'markdown' }, vscode = false },

  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
}, {
  ui = {
    icons = {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.cmd.colorscheme 'default'
