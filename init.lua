require 'config.setup'

require('lazy').setup({
  -- local plugin configuration
  { import = 'plugins' },
  { import = 'plugins.dap.dap' },
  { import = 'plugins.lang.markdown', ft = { 'markdown' } },

  'wakatime/vim-wakatime', -- code time tracking goodness
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  { 'qpkorr/vim-bufkill', event = 'VeryLazy' },
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
