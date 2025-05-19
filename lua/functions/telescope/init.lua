local M = {}

M.dotfiles = require('functions.telescope.dotfiles').run
M.notes = require('functions.telescope.notes').run
M.move_file = require('functions.telescope.move_file').run
M.vertical_tabs = require('functions.telescope.vertical_tabs').run

return M
