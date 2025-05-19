local M = {}

local builtin = require 'telescope.builtin'

--- Search through ~/.dotfiles files
M.run = function()
  builtin.find_files {
    prompt_title = '< Notes >',
    -- layout_config = {
    --   prompt_position = 'top',
    -- },
    -- sorting_strategy = 'ascending',
    search_dirs = {
      '~/notes',
    },
    hidden = true,
    find_command = {
      'fd',
      '.',
      '~/.notes',
      '--type=file',
      -- '--hidden',
    },
  }
end

return M
