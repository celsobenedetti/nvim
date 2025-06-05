--- C is table that holds configuration / options / utility functions that may be required
--- anywhere in the neovim config
C = {
  opt = require 'config.global.options', --- Global options
  ui = require 'config.ui.ui', --- UI config

  lsp = require 'lib.utils.lsp', --- LSP util functions NOTE: I'm not using this anywhere, why did I add it?
  cwd = require 'lib.utils.cwd', --- CWD util functions
  utils = require 'config.global.utils', -- Misc util functions
  url = require 'config.global.urls', -- Useful URLS
}
