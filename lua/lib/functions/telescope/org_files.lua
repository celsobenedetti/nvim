local M = {}

local builtin = require 'telescope.builtin'

--- Search org files in notes folder
M.run = function()
  builtin.find_files {
    prompt_title = '< Org files >',
    search_file = '*.org',
    search_dirs = {
      '/home/celso/notes',
    },
    cwd = '/home/celso/notes',
    hidden = true,
  }
end

return M
