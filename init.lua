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
  ui = C.UI.lazy,
})

C.UI.set_colorscheme(C.UI.colorscheme_1)
