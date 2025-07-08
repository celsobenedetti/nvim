local M = {}

local builtin = require 'telescope.builtin'
local pkms_config = require 'config.pkms'

--- Search org files in notes folder
M.run = function()
  builtin.find_files {
    prompt_title = '< Org files >',
    search_file = '*.org',
    search_dirs = {
      pkms_config.NOTES,
    },
    cwd = pkms_config.NOTES,
    hidden = true,
  }
end

return M
