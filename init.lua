require 'c.core.config'

require('lazy').setup({

  { import = 'c.core.plugins' },

  { import = 'c.modules.ui' },
  { import = 'c.modules.editor' },

  { import = 'c.modules.ai' },
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

require('c.functions').set_colorscheme(UI.colorscheme_1)
