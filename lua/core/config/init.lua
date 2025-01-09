---@diagnostic disable: lowercase-global
map = vim.keymap.set

require 'core.config.options'
require 'core.config.lazy'
require 'core.config.globals'
require 'core.config.keymaps'
require 'core.config.sensible'
require 'core.config.autocmds'
require 'core.config.commands'
require 'core.config.toggles'

-- `:help modeline`
--
-- ts=2: tabstop is set to 2 spaces
-- sts=2: softtabstop is set to 2 spaces
-- sw=2: shiftwidth is set to 2 spaces
-- et: expandtab is enabled, which means Vim will use spaces instead of tabs for indentation
-- vim: ts=2 sts=2 sw=2 et
