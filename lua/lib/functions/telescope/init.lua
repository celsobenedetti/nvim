local M = {}

M.dotfiles = require('lib.functions.telescope.dotfiles').run
M.notes = require('lib.functions.telescope.notes').run
M.move_file = require('lib.functions.telescope.move_file').run
M.vertical_tabs = require('lib.functions.telescope.vertical_tabs').run
M.org_files = require('lib.functions.telescope.org_files').run

return M
