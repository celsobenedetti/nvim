local M = {}

local builtin = require 'telescope.builtin'

--- Search through ~/.dotfiles files
M.run = function()
  builtin.find_files {
    prompt_title = '< Dotfiles >',
    -- layout_config = {
    --   prompt_position = 'top',
    -- },
    -- sorting_strategy = 'ascending',
    search_dirs = {
      '~/.dotfiles',
    },
    cwd = '~/.dotfiles',
    hidden = true,
    -- find_command = {
    --   'fd',
    --   '.',
    --   '~/.dotfiles',
    --   '--type=file',
    --   '--hidden',
    -- },
  }
end

return M
