-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require 'c.core.config.options'
require 'c.core.config.sensible'
require 'c.core.config.keymaps'
require 'c.core.config.autocmds'
require 'c.core.config.commands'
require 'c.core.config.toggles'

-- `:help modeline`
--
-- ts=2: tabstop is set to 2 spaces
-- sts=2: softtabstop is set to 2 spaces
-- sw=2: shiftwidth is set to 2 spaces
-- et: expandtab is enabled, which means Vim will use spaces instead of tabs for indentation
-- vim: ts=2 sts=2 sw=2 et
