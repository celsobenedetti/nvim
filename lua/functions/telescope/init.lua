local M = {}

M.dotfiles = require('functions.telescope.dotfiles').run
M.move_note = require('functions.telescope.move_note').run
M.vertical_tabs = require('functions.telescope.vertical_tabs').run

return M
