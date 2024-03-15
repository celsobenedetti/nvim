require 'c.core.config'

require('lazy').setup({
  { import = 'c.core.plugins' },

  { import = 'c.modules.editor' },
  { import = 'c.modules.dap' },
  { import = 'c.modules.typescript', ft = { 'typescript', 'typescriptreact' } },
  { import = 'c.modules.markdown', ft = { 'markdown', 'gitcommit' } },
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
