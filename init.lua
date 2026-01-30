require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.base' }, -- base plugins, used in every "init.lua"
    { import = 'modules.core' }, -- core plugins, used in the main "init.lua"
    { import = 'modules.git' },
    { import = 'modules.editor' },
    { import = 'modules.overseer' },
    { import = 'modules.dap' },
    { import = 'modules.ai' },
    { import = 'modules.ui' },
    { import = 'modules.markdown' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
    { import = 'modules.tmux' },
  },
  change_detection = { notify = false },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  },
  performance = vim.g.lazy_nvim_config.performance,
})
