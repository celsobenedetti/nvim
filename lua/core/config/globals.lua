--- C is table that holds configuration / options / utility functions that may be required
--- anywhere in the neovim config
C = {
  opt = require 'core.config.global.options', --- Global options
  ui = require 'core.config.ui.ui', --- UI config

  lsp = require 'lib.utils.lsp', --- LSP util functions
  cwd = require 'lib.utils.cwd', --- CWD util functions
  utils = require 'core.config.global.utils', -- Misc util functions
  url = require 'core.config.global.urls', -- Useful URLS
}
