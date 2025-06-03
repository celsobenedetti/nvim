---@diagnostic disable: lowercase-global
map = vim.keymap.set

require 'config.globals'
require 'config.options'
require 'config.lazy'
require 'config.keymaps'
require 'config.sensible'
require 'config.autocmds'
require 'config.commands'
require 'config.toggles'

-- `:help modeline`
--
-- ts=2: tabstop is set to 2 spaces
-- sts=2: softtabstop is set to 2 spaces
-- sw=2: shiftwidth is set to 2 spaces
-- et: expandtab is enabled, which means Vim will use spaces instead of tabs for indentation
-- vim: ts=2 sts=2 sw=2 et
