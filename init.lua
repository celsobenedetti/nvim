require 'c.core.config'

require('lazy').setup({

  { 'b0o/schemastore.nvim', lazy = true },
  { import = 'c.core.plugins' },

  { import = 'c.modules.editor' },
  { import = 'c.modules.dap' },
  { import = 'c.modules.trouble' },

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

require('c.functions').set_colorscheme(vim.g.code_colorscheme)
