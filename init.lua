require 'c.core.config'

require('lazy').setup({
  { import = 'c.core.plugins' },

  { import = 'c.modules.editor' },
  { import = 'c.modules.dap' },
  { import = 'c.modules.typescript' },
  { import = 'c.modules.markdown' },
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

vim.cmd.colorscheme(vim.g.code_colorscheme)
