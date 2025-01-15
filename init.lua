require 'core.config'

require('lazy').setup({
  { import = 'core.plugins' },

  { import = 'modules.editor' },
  { import = 'modules.git' },
  { import = 'modules.ui', enabled = not C.opt.performance },

  { import = 'modules.ai' },
  { import = 'modules.dap' },
  { import = 'modules.trouble' },

  { import = 'modules.typescript' },
  { import = 'modules.markdown' },
}, {
  ui = C.UI.lazy,
})

C.UI.set_colorscheme(C.UI.colorscheme_1)
