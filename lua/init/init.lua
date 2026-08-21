vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('vim._core.ui2').enable({
  msg = {
    -- Route `:!` stdout/stderr to the pager buffer instead of the cmdline, so
    -- `:!man tmux` opens the output in a dedicated scrollable buffer.
    targets = { shell_out = 'pager', shell_err = 'pager' },
  },
})

require('init.globals')
require('init.pre')
require('init.lazy')
require('init.colors')
require('init.options')
require('init.sensible')
