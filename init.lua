require 'config.lazy'
require 'config.globals'

require('lazy').setup {
  spec = {
    { 'LazyVim/LazyVim', import = 'lazyvim.plugins', opts = { colorscheme = function() end } },
    { import = 'lazyvim.plugins.extras.ui.smear-cursor' },
    { import = 'lazyvim.plugins.extras.ui.treesitter-context' },
    { import = 'lazyvim.plugins.extras.lang.git' },
    { import = 'lazyvim.plugins.extras.lang.go' },
    { import = 'lazyvim.plugins.extras.lang.typescript' },
    { import = 'lazyvim.plugins.extras.lang.tailwind' },
    { import = 'lazyvim.plugins.extras.lang.docker' },
    { import = 'lazyvim.plugins.extras.lang.json' },
    { import = 'lazyvim.plugins.extras.lang.yaml' },
    { import = 'lazyvim.plugins.extras.lang.toml' },
    { import = 'lazyvim.plugins.extras.lang.terraform' },

    { import = 'lazyvim.plugins.extras.coding.blink' },
    { import = 'lazyvim.plugins.extras.coding.neogen' },
    { import = 'lazyvim.plugins.extras.coding.luasnip' },
    { import = 'lazyvim.plugins.extras.dap.core' },
    { import = 'lazyvim.plugins.extras.dap.nlua' },
    { import = 'lazyvim.plugins.extras.test.core' },
    { import = 'lazyvim.plugins.extras.ai.supermaven' },
    -- { import = 'lazyvim.plugins.extras.ai.sidekick' },

    -- { import = "lazyvim.plugins.extras.formatting.prettier" },
    -- { import = 'lazyvim.plugins.extras.linting.eslint' },
    { import = 'lazyvim.plugins.extras.editor.outline' },
    { import = 'lazyvim.plugins.extras.editor.snacks_picker' },

    { import = 'lazyvim.plugins.extras.util.mini-hipatterns' },
    { import = 'lazyvim.plugins.extras.util.dot' },
    { import = 'lazyvim.plugins.extras.util.octo' },
    { import = 'lazyvim.plugins.extras.util.rest' },
    { import = 'lazyvim.plugins.extras.util.startuptime' },

    { 'wakatime/vim-wakatime' }, -- code time tracking goodness
    { import = 'modules.core' },
    { import = 'modules.tmux' },
    { import = 'modules.lang' },
    { import = 'modules.overseer' },
    { import = 'modules.editor' },
    { import = 'modules.zk' },
    { import = 'modules.ui' },
    { import = 'modules.ai' },
    { import = 'modules.git' },

    -- lazyload
    { 'b0o/SchemaStore.nvim', lazy = true, ft = { 'json', 'yaml', 'toml' } },

    { import = 'lib.plugins.performance' },
    { import = 'lib.plugins.disable' },
    { import = 'plugins' }, --omarchy theme
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        'gzip',
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}

require 'config.commands'
require 'config.sensible'

require 'lib.modules.transparency'
