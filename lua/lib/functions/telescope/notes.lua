local M = {}

local builtin = require 'telescope.builtin'
local pkms_config = require 'config.pkms'

--- Search through ~/.dotfiles files
M.run = function()
  builtin.find_files {
    prompt_title = '< Notes >',
    -- layout_config = {
    --   prompt_position = 'top',
    -- },
    -- sorting_strategy = 'ascending',
    search_dirs = {
      pkms_config.NOTES,
    },
    cwd = pkms_config.NOTES,
    hidden = true,
    -- find_command = {
    --   'fd',
    --   '.',
    --   '~/.notes',
    --   '--type=file',
    --   -- '--hidden',
    -- },
  }
end

return M
