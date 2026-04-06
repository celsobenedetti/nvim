require('vim._core.ui2').enable()

require('init')

require('lazy').setup({
  spec = {
    { import = 'modules.base' }, -- hard requirements throught the config
    { import = 'modules.core' }, -- plugins for core functionality
    { import = 'modules.git' },
    { import = 'modules.editor' },
    { import = 'modules.overseer' },
    { import = 'modules.ui' },
    { import = 'modules.zk' },
    { import = 'modules.orgmode' },
    { import = 'modules.omarchy' },
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
