local M = {}

M.dotfiles = require('c.functions.telescope.dotfiles').run
M.move_note = require('c.functions.telescope.move_note').run
M.vertical_tabs = require('c.functions.telescope.vertical_tabs').run

return M
