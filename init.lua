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
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
